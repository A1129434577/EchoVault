import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/shared/widgets/shared_button.dart';
import 'package:echo_vault/shared/widgets/empty_state_view.dart';
import 'package:echo_vault/shared/widgets/progress_view.dart';

enum ResourceStatus { idl, loading, source, empty, error }

class ResourceStateView extends StatelessWidget {
  final ResourceStatus state;
  final Widget child;
  final VoidCallback? action;
  const ResourceStateView({
    super.key,
    this.state = ResourceStatus.idl,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    if (state == ResourceStatus.loading) {
      return Column(
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
      return EmptyStateView();
    } else if (state == ResourceStatus.error) {
      return EmptyStateView(
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
    return child;
  }
}
