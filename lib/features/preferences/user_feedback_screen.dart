import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';
import 'package:echo_vault/shared/widgets/dialog_text_field.dart';
import 'package:echo_vault/shared/widgets/navigation_bar_views.dart';
import 'package:echo_vault/shared/widgets/background_surface.dart';

class TitleTextInputView extends StatelessWidget {
  final String title;
  final String placeholder;
  final FormFieldValidator<String>? validator;
  final TextEditingController? controller;

  const TitleTextInputView({
    super.key,
    required this.title,
    required this.placeholder,
    this.validator,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16)),
        SizedBox(height: 12),
        DialogTextField(
          controller: controller,
          style: TextStyle(fontSize: 12),
          fillColor: Colors.white,
          hintText: placeholder,
          maxLines: 5,
          maxLength: 200,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              width: 1,
              color: Color(0xff1F1F1F).withAlpha((255 * 0.08).round()),
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(width: 1, color: Color(0xffFF0E0E)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({super.key});

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BackgroundSurface(
      child: Scaffold(
        appBar: AppBar(
          leading: AppBlackBackButton(),
          title: Text('Feedback'.translate),
          actions: [
            AppBarAction(
              iconName: Assets.images.status.completionMark.path,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Get.back();
                  MessageOverlay.presentSuccess(
                    'Feedback submitted successfully.'.translate,
                  );
                }
              },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                TitleTextInputView(
                  title: 'Feedback'.translate,
                  placeholder: 'Please input'.translate,
                  controller: _feedbackController,
                  validator: (content) {
                    if (content == null || content.isEmpty) {
                      return 'Please enter your feedback.'.translate;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3),
                ValueListenableBuilder(
                  valueListenable: _feedbackController,
                  builder:
                      (
                        BuildContext context,
                        TextEditingValue feedbackController,
                        Widget? child,
                      ) {
                        return Container(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${feedbackController.text.length}/200',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: feedbackController.text.length == 200
                                  ? Color(0xffFF0E0E)
                                  : Color(
                                      0xff141414,
                                    ).withAlpha((255 * 0.75).round()),
                            ),
                          ),
                        );
                      },
                ),
                SizedBox(height: 50),
                TitleTextInputView(
                  title: 'Email Address'.translate,
                  placeholder: 'Please input'.translate,
                  validator: (content) {
                    if (content == null || content.isEmpty) {
                      return 'Please enter your email address.'.translate;
                    } else if (!content.isEmail) {
                      String messageLocal =
                          'Please fill in a valid email address.'.translate;
                      MessageOverlay.presentError(messageLocal);
                      return messageLocal;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
