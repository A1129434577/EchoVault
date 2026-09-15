import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/shared/widgets/shared_button.dart';
import 'package:echo_vault/shared/widgets/empty_state_view.dart';
import 'package:echo_vault/shared/widgets/progress_view.dart';

enum ResourceStatus { idl, loading, source, empty, error }

class ResourceStateView extends StatelessWidget {
  final ResourceStatus state;
  final Widget child;
  final bool isFadeChild;
  final VoidCallback? action;
  const ResourceStateView({
    super.key,
    this.state = ResourceStatus.idl,
    required this.child,
    this.isFadeChild=false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    Widget? stateWidget;
    if (state == ResourceStatus.loading) {
      stateWidget = Column(
        children: [
          Spacer(flex: 3),
          Container(
            alignment: Alignment.center,
            child: SizedBox(width: 28, child: ProgressView()),
          ),
          Spacer(flex: 4),
        ],
      );
    } else if (state == ResourceStatus.empty) {
      stateWidget = EmptyStateView();
    } else if (state == ResourceStatus.error) {
      stateWidget = EmptyStateView(
        title: 'Network error.',
        action: action != null
            ? SizedBox(
                height: 40,
                width: 100,
                child: SharedButton(
                  onPressed: action,
                  title: 'Retry'.translate,
                ),
              )
            : null,
      );
    }
    if(isFadeChild){
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: stateWidget==null?1:0,
            child: child,
          ),
          ?stateWidget,
        ],
      );
    }
    if(stateWidget != null) {
      return stateWidget;
    }
    return child;
  }
}
