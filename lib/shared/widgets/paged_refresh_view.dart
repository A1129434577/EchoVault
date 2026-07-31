import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:echo_vault/shared/widgets/empty_state_view.dart';
import 'package:echo_vault/shared/widgets/progress_view.dart';

class PagedRefreshView extends StatelessWidget {
  final ERChildBuilder? childBuilder;
  final Widget? child;
  final EasyRefreshController? controller;
  final FutureOr Function()? onRefresh;
  final FutureOr Function()? onLoading;
  final EdgeInsetsGeometry footerPadding;
  final bool refreshOnStart;
  final bool? isEmpty;

  const PagedRefreshView({
    super.key,
    this.controller,
    this.childBuilder,
    this.child,
    this.onRefresh,
    this.onLoading,
    this.footerPadding = EdgeInsets.zero,
    this.refreshOnStart = false,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (childBuilder != null) {
      return EasyRefresh.builder(
        controller: controller,
        onRefresh: onRefresh,
        onLoad: onLoading,
        triggerAxis: Axis.vertical,
        refreshOnStart: refreshOnStart,
        canRefreshAfterNoMore: true,
        header: _header(),
        footer: _footer(padding: footerPadding),
        childBuilder: (context, physics) {
          return isEmpty == true
              ? EmptyStateView()
              : childBuilder!(context, physics);
        },
      );
    }
    return EasyRefresh(
      controller: controller,
      onRefresh: onRefresh,
      onLoad: onLoading,
      triggerAxis: Axis.vertical,
      refreshOnStart: refreshOnStart,
      header: _header(),
      footer: _footer(),
      child: isEmpty == true ? EmptyStateView() : child,
    );
  }

  Header _header() {
    return ClassicHeader(
      showText: false,
      showMessage: false,
      pullIconBuilder:
          (BuildContext context, IndicatorState state, double animation) {
            return ProgressView();
          },
    );
  }

  Footer _footer({EdgeInsetsGeometry padding = EdgeInsets.zero}) {
    return ClassicFooter(
      showText: false,
      showMessage: false,
      triggerOffset: 30 + padding.vertical,
      pullIconBuilder:
          (BuildContext context, IndicatorState state, double animation) {
            return state.result == IndicatorResult.noMore
                ? SizedBox()
                : Padding(padding: padding, child: ProgressView());
          },
    );
  }
}
