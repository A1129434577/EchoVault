import 'package:flutter/cupertino.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/network/ytm_network.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/parse/parse_util.dart';

class GroupMoreController with ChangeNotifier {
  final FileGroup fileGroup;
  GroupMoreController({
    required this.fileGroup,
  });

  //有可能是主页样式的分组，有可能是单个样式的gird
  ValueNotifier<List<FileGroup>> resourceList = ValueNotifier([]);

  Future queryData() async {
    Map<String, dynamic>? params = {
      'browseId': fileGroup.id!,
      'params': fileGroup.params,
    };
    dynamic result = await YTMNetwork.post(
      url: YTMApis.detail,
      prams: params,
    );
    dynamic list = ParseUtil.parse<List>(result, SectionListParseKeys.initResourceList);
    list ??= ParseUtil.parse<List>(result, SectionListParseKeys.tapMoreResourceList)??[];
    list = await CommonParse.parseContents(list);
    resourceList.value = list;
  }
}