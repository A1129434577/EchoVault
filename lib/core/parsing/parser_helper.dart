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
  static const String positionField = 'index';
  static const String matchField = 'key';
  static const String expectedValueField = 'value';
  static const String nestedFilterField = 'filters';
  static const String childMatchField = 'child_key';
  static const String childValueField = 'child_value';

  ///从原始数据当中通过树形解析key列表解析到下层数据
  static T? parse<T>(dynamic parentDataArg, List parseKeysArg) {
    dynamic payload;
    if (parentDataArg is Map) {
      payload = {}..addAll(parentDataArg);
    } else if (parentDataArg is List) {
      payload = [...parentDataArg];
    }
    for (var key in parseKeysArg) {
      try {
        if (payload == null) {
          //如果data没找到了，就没有必要再走了
          break;
        }
        if (key is String) {
          //如果是字符串key直接递归取值
          payload = payload[key];
        } else if ((key is Map) && (payload is List)) {
          //如果是filter map则从数组中筛选出符合的item
          int? itemIndex = key[ParserHelper.positionField];
          String? filterKeyLocal = key[ParserHelper.matchField];
          String? filterValueLocal = key[ParserHelper.expectedValueField];
          Map? filtersLocal = key[ParserHelper.nestedFilterField];
          if (itemIndex != null) {
            while (itemIndex! > payload.length - 1) {
              itemIndex--;
            }
            if (itemIndex < payload.length) {
              if (itemIndex > -1) {
                payload = payload[itemIndex];
              } else {
                payload = payload.firstOrNull;
              }
            }
          } else if (filterKeyLocal != null && filterValueLocal != null) {
            for (var e in payload) {
              if (e[filterKeyLocal] == filterValueLocal) {
                payload = e;
              }
            }
          } else if (filterKeyLocal != null) {
            List filteredListLocal = [];
            for (var e in payload) {
              if (e is Map && e.containsKey(filterKeyLocal)) {
                filteredListLocal.add(e);
              }
            }
            payload = filteredListLocal;
          } else if (filtersLocal is Map) {
            String? filterKeyLocal =
                filtersLocal[ParserHelper.nestedFilterField];
            String? childKeyLocal = filtersLocal[ParserHelper.childMatchField];
            List filteredListLocal = [];
            for (var e in payload) {
              if (e is Map) {
                var nestedEntry = e[filterKeyLocal];
                if (nestedEntry is Map) {
                  if (nestedEntry[childKeyLocal] != null) {
                    // if (child[childKey] == childValue) {
                    filteredListLocal.add(e);
                  }
                }
              }
            }
            payload = filteredListLocal;
          }
        }
      } catch (e) {
        Get.log('youtube解析报错：$e', isError: true);
      }
    }
    // if(data != null &&  ((data is T) == false)){
    if ((payload is T) == false) {
      // Get.log('youtube解析报错：类型${data.runtimeType}不符合预期${T.runtimeType}');
      return null;
    }
    return payload;
  }
}
