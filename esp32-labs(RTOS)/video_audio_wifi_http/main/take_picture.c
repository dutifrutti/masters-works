#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

#include "esp_event.h"
#include "nvs_flash.h"
#include "esp_log.h"

#include "app_wifi.h"
#include "esp_camera.h"
#include "driver/i2s_pdm.h"
#include "driver/spi_common.h"

#define PDM_CLK_IO          42
#define PDM_DATA_IO         41
#define PDM_SAMPLE_RATE     16000
#define PDM_BITS_PER_SAMPLE 16
#define PDM_CHANNELS_NUM    1
#define AUDIO_BUF_SAMPLES   (PDM_SAMPLE_RATE/10)
#define AUDIO_BUF_BYTES     (AUDIO_BUF_SAMPLES * sizeof(int16_t))

typedef struct {
    uint8_t *data;
    size_t   len;
} audio_frame_t;

static QueueHandle_t xQueueIFrame = NULL;
static QueueHandle_t xQueueAudio = NULL;

i2s_chan_handle_t rx_handle = NULL;

#define TEST_ESP_OK(ret) assert(ret == ESP_OK)
#define TEST_ASSERT_NOT_NULL(ret) assert(ret != NULL)

static bool auto_jpeg_support = false; // whether the camera sensor support compression or JPEG encode

static const char *TAG = "video s_server";

esp_err_t start_stream_server(const QueueHandle_t frame_i,
                              const QueueHandle_t audio_q,
                              const bool return_fb);

static esp_err_t init_camera(uint32_t xclk_freq_hz, pixformat_t pixel_format, framesize_t frame_size, uint8_t fb_count)
{
    camera_config_t camera_config = {
        .pin_pwdn = -1,
        .pin_reset = -1,
        .pin_xclk = 10,
        .pin_sscb_sda = 40,
        .pin_sscb_scl = 39,

        .pin_d7 = 48,
        .pin_d6 = 11,
        .pin_d5 = 12,
        .pin_d4 = 14,
        .pin_d3 = 16,
        .pin_d2 = 18,
        .pin_d1 = 17,
        .pin_d0 = 15,
        .pin_vsync = 38,
        .pin_href = 47,
        .pin_pclk = 13,

        .xclk_freq_hz = xclk_freq_hz,
        .ledc_timer = LEDC_TIMER_0,
        .ledc_channel = LEDC_CHANNEL_0,

        .pixel_format = pixel_format, //JPEG
        .frame_size = frame_size,    //QQVGA-UXGA, sizes above QVGA are not been recommended when not JPEG format.

        .jpeg_quality = 10, //0-63
        .fb_count = fb_count,       //if more than one, i2s runs in continuous mode. Use only with JPEG.
        .grab_mode = CAMERA_GRAB_LATEST,
        .fb_location = CAMERA_FB_IN_PSRAM
    };

    //initialize the camera
    esp_err_t ret = esp_camera_init(&camera_config);

    sensor_t *s = esp_camera_sensor_get();
    s->set_vflip(s, 1);//flip it back
    //initial sensors are flipped vertically and colors are a bit saturated
    if (s->id.PID == OV3660_PID) {
        s->set_saturation(s, -2);//lower the saturation
    }

    if (s->id.PID == OV3660_PID || s->id.PID == OV2640_PID) {
        s->set_vflip(s, 1); //flip it back
    } else if (s->id.PID == GC0308_PID) {
        s->set_hmirror(s, 0);
    } else if (s->id.PID == GC032A_PID) {
        s->set_vflip(s, 1);
    }

    camera_sensor_info_t *s_info = esp_camera_sensor_get_info(&(s->id));

    if (ESP_OK == ret && PIXFORMAT_JPEG == pixel_format && s_info->support_jpeg == true) {
        auto_jpeg_support = true;
    }

    return ret;
}

void init_microphone(void)
{
    i2s_chan_config_t chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_AUTO, I2S_ROLE_MASTER);
    ESP_ERROR_CHECK(i2s_new_channel(&chan_cfg, NULL, &rx_handle));

    i2s_pdm_rx_config_t pdm_rx_cfg = {
        .clk_cfg = I2S_PDM_RX_CLK_DEFAULT_CONFIG(PDM_SAMPLE_RATE),
        /* The default mono slot is the left slot (whose 'select pin' of the PDM microphone is pulled down) */
        .slot_cfg = I2S_PDM_RX_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO),
        .gpio_cfg = {
            .clk = PDM_CLK_IO,
            .din = PDM_DATA_IO,
            .invert_flags = {
                .clk_inv = false,
            },
        },
    };
    ESP_ERROR_CHECK(i2s_channel_init_pdm_rx_mode(rx_handle, &pdm_rx_cfg));
    ESP_ERROR_CHECK(i2s_channel_enable(rx_handle));
}

void audio_capture_task(void *arg) {
    audio_frame_t *audio_frame = (audio_frame_t *)malloc(sizeof(audio_frame_t));
    if (!audio_frame) {
        ESP_LOGE(TAG, "Failed to allocate memory for audio frame");
        vTaskDelete(NULL);
    }

    audio_frame->data = (uint8_t *)malloc(AUDIO_BUF_BYTES);
    if (!audio_frame->data) {
        ESP_LOGE(TAG, "Failed to allocate memory for audio data");
        free(audio_frame);
        vTaskDelete(NULL);
    }
    audio_frame->len = AUDIO_BUF_BYTES;

    while (true) {
        size_t bytes_read;
        esp_err_t ret = i2s_channel_read(rx_handle, audio_frame->data, AUDIO_BUF_BYTES, &bytes_read, portMAX_DELAY);
        if (ret == ESP_OK && bytes_read > 0) {
            xQueueSend(xQueueAudio, &audio_frame, portMAX_DELAY);
        }
    }
}

static void video_capture_task(void *arg) {
    camera_fb_t *frame;

    ESP_LOGI(TAG, "Starting video capture task");

        while (true) {
        frame = esp_camera_fb_get();
        if (frame) {
            xQueueSend(xQueueIFrame, &frame, portMAX_DELAY);
        }
    }
}
void app_main()
{
    app_wifi_main();
    init_microphone();
    TEST_ESP_OK(init_camera(10000000, PIXFORMAT_JPEG, FRAMESIZE_QVGA, 2));  

    xQueueIFrame = xQueueCreate(2, sizeof(camera_fb_t *));  
    xQueueAudio = xQueueCreate(2, sizeof(audio_frame_t *));

    xTaskCreate(video_capture_task, "video_capture_task", 4096, NULL, 5, NULL);
    xTaskCreate(audio_capture_task, "audio_capture_task", 4096, NULL, 5, NULL);

    TEST_ESP_OK(start_stream_server(xQueueIFrame, xQueueAudio, true));


}