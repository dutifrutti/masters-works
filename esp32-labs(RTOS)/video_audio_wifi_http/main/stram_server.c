/*
 * SPDX-FileCopyrightText: 2022-2023 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"

#include "esp_http_server.h"
#include "img_converters.h"
#include "sdkconfig.h"
#include "esp_log.h"

#define PART_BOUNDARY "123456789000000000000987654321"
static const char *_STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char *_STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char *_STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %u\r\nX-Timestamp: %d.%06d\r\n\r\n";
static QueueHandle_t xQueueFrameI = NULL;
static QueueHandle_t xQueueAudio  = NULL;
static bool gReturnFB = true;
static httpd_handle_t video_httpd = NULL;
static httpd_handle_t audio_httpd = NULL;

typedef struct {          
    uint8_t *data;
    size_t   len;
} audio_frame_t;

static const char *TAG = "stream_s";

static esp_err_t stream_handler(httpd_req_t *req)
{
    camera_fb_t *frame = NULL;
    struct timeval _timestamp;
    esp_err_t res = ESP_OK;
    size_t _jpg_buf_len = 0;
    uint8_t *_jpg_buf = NULL;
    char *part_buf[128];

    res = httpd_resp_set_type(req, _STREAM_CONTENT_TYPE);
    if (res != ESP_OK) {
        return res;
    }

    httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
    httpd_resp_set_hdr(req, "X-Framerate", "60");

    while (true) {
        if (xQueueReceive(xQueueFrameI, &frame, portMAX_DELAY)) {
            _timestamp.tv_sec = frame->timestamp.tv_sec;
            _timestamp.tv_usec = frame->timestamp.tv_usec;

            if (frame->format == PIXFORMAT_JPEG) {
                _jpg_buf = frame->buf;
                _jpg_buf_len = frame->len;
            } else if (!frame2jpg(frame, 60, &_jpg_buf, &_jpg_buf_len)) {
                ESP_LOGE(TAG, "JPEG compression failed");
                res = ESP_FAIL;
            }
        } else {
            res = ESP_FAIL;
        }

        if (res == ESP_OK) {
            res = httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY));
            if (res == ESP_OK) {
                size_t hlen = snprintf((char *)part_buf, 128, _STREAM_PART, _jpg_buf_len, _timestamp.tv_sec, _timestamp.tv_usec);
                res = httpd_resp_send_chunk(req, (const char *)part_buf, hlen);
            }
            if (res == ESP_OK) {
                res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
            }

            if (frame->format != PIXFORMAT_JPEG) {
                free(_jpg_buf);
                _jpg_buf = NULL;
            }
        }

        if (gReturnFB) {
            esp_camera_fb_return(frame);
        } else {
            free(frame->buf);
        }

        if (res != ESP_OK) {
            ESP_LOGE(TAG, "Break stream handler");
            break;
        }
    }

    return res;
}

static esp_err_t audio_stream_handler(httpd_req_t *req)
{
    audio_frame_t *aframe = NULL;
    esp_err_t      res;

    res = httpd_resp_set_type(req, "application/octet-stream");
    if (res != ESP_OK) return res;

    httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
    httpd_resp_set_hdr(req, "X-Sample-Rate", "16000");
    httpd_resp_set_hdr(req, "X-Bits-Per-Sample", "16");

    while (true) {
        if (xQueueReceive(xQueueAudio, &aframe, portMAX_DELAY)) {
            res = httpd_resp_send_chunk(req,
                                        (const char *)aframe->data,
                                        aframe->len);
            if (res != ESP_OK) {
                ESP_LOGE(TAG, "Break audio stream handler");
               break;
            }
        } else {
           res = ESP_FAIL;
            break;
        }
    }
    return res;
}

esp_err_t start_stream_server(const QueueHandle_t frame_i, const QueueHandle_t audio_q,
                            const bool return_fb)
{
    xQueueFrameI = frame_i;
    xQueueAudio = audio_q;
    gReturnFB = return_fb;

    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.stack_size = 5120;
    httpd_uri_t stream_uri = {
        .uri = "/stream",
        .method = HTTP_GET,
        .handler = stream_handler,
        .user_ctx = NULL
    };


        httpd_uri_t audio_uri  = {
        .uri      = "/audio",
        .method   = HTTP_GET,
        .handler  = audio_stream_handler,
        .user_ctx = NULL
    };

    httpd_config_t acfg = config;
    acfg.server_port    = 81;
    acfg.ctrl_port      = 32769;

    esp_err_t err = httpd_start(&video_httpd, &config);
    if (err == ESP_OK) {
        err = httpd_register_uri_handler(video_httpd, &stream_uri);
   }
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Video server start failed: %s", esp_err_to_name(err));
        return err;
   }

    /* -------- audio server -------- */
    err = httpd_start(&audio_httpd, &acfg);
    if (err == ESP_OK) {
        err = httpd_register_uri_handler(audio_httpd, &audio_uri);
    }
    if (err == ESP_OK) {
        ESP_LOGI(TAG,
                 "Video : http://<IP>:80/stream   |   Audio : http://<IP>:81/audio");
   } else {
        ESP_LOGE(TAG, "Audio server start failed: %s", esp_err_to_name(err));
    }
    return err;
    //return ESP_FAIL;
}
