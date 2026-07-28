import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/widgets/common_button.dart';
import 'package:echo_vault/widgets/empty_widget.dart';
import 'package:echo_vault/widgets/loading_widget.dart';

enum ResourceStatus{
  idl,
  loading,
  source,
  empty,
  error
}

class BaseStatusWidget extends StatelessWidget {
  final ResourceStatus state;
  final Widget child;
  final VoidCallback? action;
  const BaseStatusWidget({
    super.key,
    this.state = ResourceStatus.idl,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    if(state == ResourceStatus.loading) {
      return Column(
        children: [
          Spacer(
            flex: 3,
          ),
          Container(
            alignment: Alignment.center,
            child: SizedBox(width: 28, child: LoadingWidget()),
          ),
          Spacer(
            flex: 4,
          ),
        ],
      );
    }
    else if(state == ResourceStatus.empty){
      return EmptyWidget();
    }
    else if(state == ResourceStatus.error){
      return EmptyWidget(
        title: 'Network error.',
        action: action!=null?SizedBox(
          height: 40,
          width: 100,
          child: CommonButton(
            onPressed: action,
            title: 'Retry'.translate,
          ),
        ):null,
      );
    }
    return child;
  }
}
