import 'package:lottie/lottie.dart';
import 'package:cosmetic_store/taxi/lib/core/helper/date_converter.dart';
import 'package:cosmetic_store/taxi/lib/core/route/route.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/app_status.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_animation.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/my_icons.dart';
import 'package:cosmetic_store/taxi/lib/core/utils/style.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/map/ride_map_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/pusher/pusher_ride_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:cosmetic_store/taxi/lib/data/controller/ride/ride_meassage/ride_meassage_controller.dart';

import 'package:cosmetic_store/taxi/lib/data/model/global/app/ride_message_model.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/message/message_repo.dart';
import 'package:cosmetic_store/taxi/lib/data/repo/ride/ride_repo.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/custom_loader/custom_loader.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/divider/custom_spacer.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/image/my_local_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/image/my_network_image_widget.dart';
import 'package:cosmetic_store/taxi/lib/presentation/components/text/header_text.dart';

import '../../../core/utils/dimensions.dart';
import '../../../core/utils/my_color.dart';
import '../../../core/utils/my_strings.dart';
import '../../../data/controller/ride/ride_meassage/new_taxi_chat_controller.dart';
import '../../components/app-bar/custom_appbar.dart';
import '../../packages/flutter_chat_bubble/chat_bubble.dart';

class RideMessageScreen extends StatefulWidget {
  String rideID;
  RideMessageScreen({super.key, required this.rideID});

  @override
  State<RideMessageScreen> createState() => _RideMessageScreenState();
}

class _RideMessageScreenState extends State<RideMessageScreen> {
  String riderName = "";
  String riderStatus = "";

  @override
  void initState() {
    super.initState();

    widget.rideID = Get.arguments?[0]?.toString() ?? widget.rideID;
    riderName = Get.arguments?[1] ?? MyStrings.inbox.tr;
    riderStatus = Get.arguments?[2] ?? "-1";

    print("🟢 [Customer Chat] InitState Started. RideID: ${widget.rideID}");

    // 🛡️ حماية التهيئة: لتفادي انهيار التطبيق إذا تم فتح الشاشة من الإشعار مباشرة
    try {
      if (!Get.isRegistered<MessageRepo>()) Get.put(MessageRepo(apiClient: Get.find()));
      if (!Get.isRegistered<RideRepo>()) Get.put(RideRepo(apiClient: Get.find()));
      if (!Get.isRegistered<RideMapController>()) Get.put(RideMapController());
      if (!Get.isRegistered<RideDetailsController>()) {
        Get.put(RideDetailsController(mapController: Get.find(), repo: Get.find()));
      }
      if (!Get.isRegistered<RideMessageController>()) {
        Get.put(RideMessageController(repo: Get.find()));
      }

      if (!Get.isRegistered<PusherRideController>()) {
        Get.put(PusherRideController(
          apiClient: Get.find(),
          rideMessageController: Get.find(),
          rideDetailsController: Get.find(),
          rideID: widget.rideID,
        ));
      }

      if (!Get.isRegistered<NewTaxiChatController>()) {
        print("🟢 [Customer Chat] Registering NewTaxiChatController for Ride: ${widget.rideID}");
        Get.put(NewTaxiChatController(rideId: widget.rideID));
      }
    } catch (e) {
      print("⚠️ [Customer Chat] تحذير أثناء تهيئة GetX (قد يكون التطبيق لا يزال يحمل): $e");
    }

    // 🛡️ تأجيل استدعاء البيانات حتى يكتمل بناء الواجهة لتفادي الشاشة البيضاء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("🟢 [Customer Chat] PostFrameCallback - تم رسم الشاشة. جاري استدعاء البيانات...");
      if (Get.isRegistered<RideMessageController>()) {
        final controller = Get.find<RideMessageController>();
        controller.initialData(widget.rideID);
        controller.updateCount(0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((time) {
      if(Get.isRegistered<RideMessageController>()){
        Get.find<RideMessageController>().updateCount(0);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    getSenderView(
        CustomClipper clipper,
        BuildContext context,
        RideMessage item,
        String imagePath,
        bool isLastMessage,
        ) =>
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          child: ChatBubble(
            clipper: clipper,
            alignment: Alignment.topRight,
            margin: const EdgeInsets.only(top: Dimensions.space3),
            backGroundColor: MyColor.primaryColor,
            shadowColor: MyColor.primaryColor.withValues(alpha: 0.01),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: MediaQuery.of(context).size.width * 0.2,
              ),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.image != null && item.image != "null")
                      InkWell(
                        splashFactory: NoSplash.splashFactory,
                        onTap: () {
                          Get.toNamed(
                            RouteHelper.previewImageScreen,
                            arguments: "$imagePath/${item.image}",
                          );
                        },
                        child: MyImageWidget(imageUrl: "$imagePath/${item.image}"),
                      ),
                    SizedBox(height: Dimensions.space2),
                    Text(
                      '${item.message}',
                      textAlign: TextAlign.start,
                      style: regularLarge.copyWith(color: Colors.white),
                    ),
                    if (isLastMessage) ...[
                      spaceDown(Dimensions.space2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          DateConverter.getTimeAgo(item.createdAt ?? ""),
                          style: regularDefault.copyWith(
                            color: Colors.white70,
                            fontSize: Dimensions.fontOverSmall,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );

    getReceiverView(
        CustomClipper clipper,
        BuildContext context,
        RideMessage item,
        String imagePath,
        bool isLastMessage,
        ) =>
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          child: ChatBubble(
            clipper: clipper,
            backGroundColor: MyColor.colorGrey.withValues(alpha: 0.09),
            shadowColor: MyColor.colorGrey.withValues(alpha: 0.01),
            margin: const EdgeInsets.only(top: Dimensions.space3),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: MediaQuery.of(context).size.width * 0.2,
              ),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.image != null && item.image != "null")
                      InkWell(
                        splashFactory: NoSplash.splashFactory,
                        onTap: () {
                          Get.toNamed(
                            RouteHelper.previewImageScreen,
                            arguments: "$imagePath/${item.image}",
                          );
                        },
                        child: MyImageWidget(imageUrl: "$imagePath/${item.image}"),
                      ),
                    SizedBox(height: Dimensions.space2),
                    Text(
                      '${item.message}',
                      style: regularLarge.copyWith(color: MyColor.getTextColor()),
                    ),
                    if (isLastMessage) ...[
                      spaceDown(Dimensions.space2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          DateConverter.getTimeAgo(item.createdAt ?? ""),
                          style: regularDefault.copyWith(
                            color: MyColor.getTextColor().withValues(alpha: 0.7),
                            fontSize: Dimensions.fontOverSmall,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );

    return GetBuilder<RideMessageController>(
      builder: (oldController) {
        return AnnotatedRegionWidget(
          child: Scaffold(
            extendBody: true,
            resizeToAvoidBottomInset: true,
            backgroundColor: MyColor.screenBgColor,
            appBar: CustomAppBar(
              title: riderName,
              backBtnPress: () {
                Get.back();
              },
              actionsWidget: [
                IconButton(
                  onPressed: () {
                    print("🔄 [Customer Chat] Refresh button pressed");
                  },
                  icon: Icon(
                    Icons.refresh_outlined,
                    color: MyColor.getPrimaryColor(),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: Get.isRegistered<NewTaxiChatController>()
                        ? Get.find<NewTaxiChatController>().getMessagesStream()
                        : const Stream.empty(),
                    builder: (context, snapshot) {

                      if (snapshot.hasError) {
                        print("❌ [Customer Chat] Stream Error: ${snapshot.error}");
                        return Center(child: Text("خطأ في الاتصال: ${snapshot.error}"));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        print("⏳ [Customer Chat] Waiting for stream data...");
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        print("⚠️ [Customer Chat] No messages found for ride ${widget.rideID}");
                        return Center(
                          child: LottieBuilder.asset(
                            MyAnimation.emptyChat,
                            repeat: false,
                            height: 200,
                          ),
                        );
                      }

                      var messages = snapshot.data!.docs;
                      print("✅ [Customer Chat] Found ${messages.length} messages.");

                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          try {
                            var doc = messages[index];
                            var data = doc.data() as Map<String, dynamic>;

                            // 🔥 1. استخدام الصيغة الدولية للوقت toIso8601String لكي لا ينهار DateConverter
                            String timeString = DateTime.now().toIso8601String();
                            if (data['createdAt'] != null) {
                              if (data['createdAt'] is Timestamp) {
                                timeString = (data['createdAt'] as Timestamp).toDate().toIso8601String();
                              } else {
                                timeString = data['createdAt'].toString();
                              }
                            }

                            RideMessage item = RideMessage(
                              message: data['message']?.toString() ?? '',
                              userId: data['userId']?.toString() ?? '0',
                              driverId: data['driverId']?.toString() ?? '0',
                              image: data['image']?.toString() ?? 'null',
                              createdAt: timeString,
                            );

                            bool isMyMessage = item.userId != "0";

                            return Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: Dimensions.space6,
                                end: Dimensions.space6,
                                bottom: Dimensions.space8,
                              ),
                              child: isMyMessage
                                  ? getSenderView(ChatBubbleClipper3(type: BubbleType.sendBubble), context, item, "", true)
                                  : getReceiverView(ChatBubbleClipper3(type: BubbleType.receiverBubble), context, item, "", true),
                            );
                          } catch (e) {
                            // 🔥 2. في حال وجود خطأ في رسالة معينة، نخفيها بدلاً من جعل الشاشة بيضاء
                            print("❌ [Customer Chat] Error building message $index: $e");
                            return const SizedBox.shrink();
                          }
                        },
                      );
                    },
                  ),
                ),

                // منطقة حقل الإدخال
                oldController.isLoading
                    ? const SizedBox.shrink()
                    : riderStatus == AppStatus.RIDE_COMPLETED
                    ? Container(
                  color: MyColor.getCardBgColor(),
                  padding: EdgeInsets.all(Dimensions.space15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: MyColor.getTextColor(),
                      ),
                      spaceSide(Dimensions.space10),
                      HeaderText(
                        text: MyStrings.rideCompleted,
                        style: semiBoldOverLarge.copyWith(color: MyColor.getTextColor()),
                      )
                    ],
                  ),
                )
                    : Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space10,
                    vertical: Dimensions.space10,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space5,
                    vertical: Dimensions.space5,
                  ),
                  decoration: BoxDecoration(
                    color: MyColor.colorWhite,
                    borderRadius: BorderRadius.circular(Dimensions.space12),
                  ),
                  child: Row(
                    children: [
                      spaceSide(Dimensions.space10),
                      // زر اختيار الصورة (لا يزال يستخدم الكنترولر القديم)
                      oldController.imageFile == null
                          ? GestureDetector(
                        onTap: () => oldController.pickFile(),
                        child: Icon(
                          Icons.image,
                          color: MyColor.primaryColor,
                        ),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.mediumRadius,
                        ),
                        child: Image.file(
                          oldController.imageFile!,
                          height: 35,
                          width: 35,
                        ),
                      ),
                      spaceSide(Dimensions.space10),

                      // حقل النص الجديد للفايربيس
                      Expanded(
                        child: GetBuilder<NewTaxiChatController>(
                            builder: (newChatController) {
                              return TextFormField(
                                controller: newChatController.messageController,
                                cursorColor: MyColor.getPrimaryColor(),
                                style: regularSmall.copyWith(color: MyColor.getTextColor()),
                                maxLines: null,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  hintText: MyStrings.writeYourMessage.tr,
                                  hintStyle: mediumDefault.copyWith(
                                    color: MyColor.bodyTextColor.withValues(alpha: 0.7),
                                  ),
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                onFieldSubmitted: (value) {
                                  print("📨 [Customer Chat] Submitting message: $value");
                                  if (newChatController.messageController.text.isNotEmpty && !newChatController.isSubmitLoading) {
                                    newChatController.sendMessage();
                                  }
                                },
                              );
                            }
                        ),
                      ),
                      spaceSide(Dimensions.space10),

                      // زر الإرسال الجديد للفايربيس
                      GetBuilder<NewTaxiChatController>(
                          builder: (newChatController) {
                            return InkWell(
                              onTap: () {
                                print("📨 [Customer Chat] Send button tapped. Msg: ${newChatController.messageController.text}");
                                if (newChatController.messageController.text.isNotEmpty && !newChatController.isSubmitLoading) {
                                  newChatController.sendMessage();
                                }
                              },
                              child: newChatController.isSubmitLoading
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: MyColor.primaryColor),
                              )
                                  : const MyLocalImageWidget(
                                imagePath: MyIcons.sendArrow,
                                width: Dimensions.space40,
                                height: Dimensions.space40,
                              ),
                            );
                          }
                      ),
                      spaceSide(Dimensions.space10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}