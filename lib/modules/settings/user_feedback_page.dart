import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/utils/toast_util.dart';
import 'package:echo_vault/widgets/alert_input_filed.dart';
import 'package:echo_vault/widgets/app_bar_widgets.dart';
import 'package:echo_vault/widgets/bg_container.dart';

class UserFeedbackPage extends StatefulWidget {
  const UserFeedbackPage({super.key});

  @override
  State<UserFeedbackPage> createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return BgContainer(
      child: Scaffold(
        appBar: AppBar(
          leading: AppBlackBackButton(),
          title: Text(
            'Feedback'.translate,
          ),
          actions: [
            AppBarAction(
              iconName: Assets.images.status.completionMark.path,
              onPressed: (){
                if(_formKey.currentState!.validate()){
                  Get.back();
                  ToastUtil.showSuccess('Feedback successful!');
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
                      return 'Please input feedback content.'.translate;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3),
                ValueListenableBuilder(
                  valueListenable: _feedbackController,
                  builder: (BuildContext context, TextEditingValue feedbackController, Widget? child) {
                    return Container(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${feedbackController.text.length}/200',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: feedbackController.text.length==200?Color(0xffFF0E0E):Color(0xff141414).withAlpha((255*0.75).round()),
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
                      return 'Please input Email Address.'.translate;
                    }else if(!content.isEmail){
                      String message = 'Please fill in a valid email address.'.translate;
                      ToastUtil.showError(message);
                      return message;
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
        Text(
          title,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 12),
        AlertInputFiled(
          controller: controller,
          style: TextStyle(fontSize: 12),
          fillColor: Colors.white,
          hintText: placeholder,
          maxLines: 5,
          maxLength: 200,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(width: 1, color: Color(0xff1F1F1F).withAlpha((255*0.08).round())),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(width: 1, color: Color(0xffFF0E0E)),
          ),
          validator: validator,
        )
      ],
    );
  }
}
