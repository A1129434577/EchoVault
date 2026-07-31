import 'package:get/get.dart';

///树形解析key list说明
/// 如果key是String：直接解析
/// 如果key是filter map则说明该层级对象是数组，解析规则如下:
/// 1.如果index字段不为空，则直接用index取；
/// 2.如果key不为空，则筛选出包含该key的对象；
/// 3.如果key和value都不为空，则筛选出item[key] = value的对象;
/// 4.如果filters（更深一层筛选条件）不为空，则筛选出item[key][child_key] = child_value的对象。
//    {
//       'index':0,
//       'key': 'filter_key',
//       'value': 'filter_value',
//       'filters': {'key': 'filter_key', 'child_key': 'child_key', 'child_value': 'child_value'}
//     },
///总的解析list如：
//  static List parseKeys = [
//     'contents',
//     'tabs',
//     {
//       YoutubeResultParse.indexKey: 0,
//     },
//     'content',
//   ];
class ParserHelper {
  static const String indexKey = 'index';
  static const String filterKey = 'key';
  static const String filterValueKey = 'value';
  static const String filtersKey = 'filters';
  static const String filterChildKey = 'child_key';
  static const String filterChildValueKey = 'child_value';

  ///从原始数据当中通过树形解析key列表解析到下层数据
  static T? parse<T>(dynamic parentData, List parseKeys) {
    dynamic data;
    if (parentData is Map) {
      data = {}..addAll(parentData);
    } else if (parentData is List) {
      data = [...parentData];
    }
    for (var key in parseKeys) {
      try {
        if (data == null) {
          //如果data没找到了，就没有必要再走了
          break;
        }
        if (key is String) {
          //如果是字符串key直接递归取值
          data = data[key];
        } else if ((key is Map) && (data is List)) {
          //如果是filter map则从数组中筛选出符合的item
          int? index = key[ParserHelper.indexKey];
          String? filterKey = key[ParserHelper.filterKey];
          String? filterValue = key[ParserHelper.filterValueKey];
          Map? filters = key[ParserHelper.filtersKey];
          if (index != null) {
            while (index! > data.length - 1) {
              index--;
            }
            if (index < data.length) {
              if (index > -1) {
                data = data[index];
              } else {
                data = data.firstOrNull;
              }
            }
          } else if (filterKey != null && filterValue != null) {
            for (var e in data) {
              if (e[filterKey] == filterValue) {
                data = e;
              }
            }
          } else if (filterKey != null) {
            List filteredList = [];
            for (var e in data) {
              if (e is Map && e.containsKey(filterKey)) {
                filteredList.add(e);
              }
            }
            data = filteredList;
          } else if (filters is Map) {
            String? filterKey = filters[ParserHelper.filtersKey];
            String? childKey = filters[ParserHelper.filterChildKey];
            List filteredList = [];
            for (var e in data) {
              if (e is Map) {
                var child = e[filterKey];
                if (child is Map) {
                  if (child[childKey] != null) {
                    // if (child[childKey] == childValue) {
                    filteredList.add(e);
                  }
                }
              }
            }
            data = filteredList;
          }
        }
      } catch (e) {
        Get.log('youtube解析报错：$e', isError: true);
      }
    }
    // if(data != null &&  ((data is T) == false)){
    if ((data is T) == false) {
      // Get.log('youtube解析报错：类型${data.runtimeType}不符合预期${T.runtimeType}');
      return null;
    }
    return data;
  }
}
