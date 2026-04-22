add_action('rest_api_init', function () {
    register_rest_route('beytei-chat/v1', '/notify', [
        'methods' => 'POST',
        'callback' => 'handle_beytei_chat_notification_smart',
        'permission_callback' => '__return_true'
    ]);
});

function handle_beytei_chat_notification_smart($request) {
    $params = $request->get_json_params();

    $order_id    = isset($params['order_id']) ? intval($params['order_id']) : 0;
    $message     = isset($params['message']) ? sanitize_text_field($params['message']) : '';
    $sender_name = isset($params['sender_name']) ? sanitize_text_field($params['sender_name']) : 'الطرف الآخر';
    $target      = isset($params['target']) ? sanitize_text_field($params['target']) : ''; 

    if (empty($order_id) || empty($target) || empty($message)) {
        return new WP_REST_Response(['success' => false, 'message' => 'بيانات ناقصة'], 400);
    }

    $order = wc_get_order($order_id);
    if (!$order) {
        return new WP_REST_Response(['success' => false, 'message' => 'الطلب غير موجود'], 404);
    }

    $fcm_token = '';

    // 🔥 1. جلب توكن الزبون (FCM العادي)
    if ($target === 'customer') {
        $fcm_token = $order->get_meta('_customer_fcm_token', true);
        if (empty($fcm_token)) $fcm_token = $order->get_meta('fcm_token', true);
        if (empty($fcm_token)) {
            $user_id = $order->get_user_id();
            if ($user_id) $fcm_token = get_user_meta($user_id, 'fcm_token', true);
        }
    } 
    // 🔥 2. جلب توكن السائق
    elseif ($target === 'driver') {
        $fcm_token = $order->get_meta('_driver_fcm_token', true);
    }

    if (empty($fcm_token)) {
        return new WP_REST_Response(['success' => false, 'message' => "توكن الـ {$target} غير متوفر في السيرفر"], 404);
    }

    $title = "رسالة جديدة من " . $sender_name;
    
    $project_id = 'beytei-me'; 
    $access_token = false;
    
    if (function_exists('beytei_get_google_api_access_token')) {
        $access_token = beytei_get_google_api_access_token();
    }

    if (!$access_token) {
        return new WP_REST_Response(['success' => false, 'message' => 'فشل الاتصال بـ Firebase - التوكن مفقود'], 500);
    }

    $url = "https://fcm.googleapis.com/v1/projects/{$project_id}/messages:send";

    // 🚀 بناء الهيكل (Payload) المصحح
    $fcm_message = [
        'message' => [
            'token' => $fcm_token,
            
            // 1. الإشعار العام
            'notification' => [
                'title' => $title,
                'body'  => $message
            ],
            
            // 2. البيانات التي يعتمد عليها الفلاتر
            'data' => [
                'title'        => $title,
                'body'         => $message,
                'type'         => 'chat_message',
                'order_id'     => strval($order_id),
                'sender_name'  => $sender_name,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
            ],
            
            // 3. إعدادات الأندرويد
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'high_importance_channel',
                    'sound' => 'woo_sound', 
                    'default_sound' => false
                ]
            ],
            
            // 4. إعدادات الآيفون (APNs) 🔥 تم التصحيح لضمان ظهور البانر
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',     
                    'apns-push-type' => 'alert'  
                ],
                'payload' => [
                    'aps' => [
                        'alert' => [            // 👈 هذا ما كان ينقص الآيفون ليظهر كبانر من الأعلى
                            'title' => $title,
                            'body'  => $message
                        ],
                        'sound' => 'default',
                        'badge' => 1,
                        'content-available' => 1 
                    ]
                ]
            ]
        ]
    ];

    $headers = [
        'Authorization' => 'Bearer ' . $access_token, 
        'Content-Type' => 'application/json'
    ];
    
    $response = wp_remote_post($url, [
        'method' => 'POST', 
        'headers' => $headers, 
        'body' => json_encode($fcm_message), 
        'sslverify' => false,
        'timeout' => 15
    ]);

    if (is_wp_error($response)) {
        return new WP_REST_Response(['success' => false, 'message' => 'خطأ في إرسال الطلب للسيرفر'], 500);
    }

    $code = wp_remote_retrieve_response_code($response);
    if ($code != 200) {
        if (function_exists('my_simple_logger')) {
            my_simple_logger("Chat Push Failed: " . wp_remote_retrieve_body($response));
        }
        return new WP_REST_Response(['success' => false, 'message' => 'فشل الإرسال من جوجل (Code '.$code.')'], 500);
    }

    return new WP_REST_Response(['success' => true, 'message' => 'تم إرسال إشعار الدردشة بنجاح'], 200);
}