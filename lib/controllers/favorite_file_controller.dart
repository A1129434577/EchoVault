import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/datebase/file_info_data_operate.dart';
import 'package:echo_vault/utils/toast_util.dart';

class FavoriteFileController with ChangeNotifier{
  static final StreamController<FileInfo> _favoriteController = StreamController.broadcast();
  static Stream<FileInfo> get favoriteStream => _favoriteController.stream;

  ValueNotifier<FileInfo?> notifier = ValueNotifier(null);

  late StreamSubscription _favoriteSubscription;
  FavoriteFileController({FileInfo? fileInfo}){
    notifier.value = fileInfo;
    _favoriteSubscription = favoriteStream.listen((newFileInfo){
      if(newFileInfo.fileId == notifier.value?.fileId){
        notifier.value?.isFavorite= newFileInfo.isFavorite;
        notifier.notifyListeners();
      }
    });
  }

  void favoriteStateChange() async {
    if(notifier.value != null){
      FileInfo fileInfo = notifier.value!;
      fileInfo.isFavorite ^= 1;
      if(fileInfo.isFavorite==1){
        ToastUtil.showMessage('Added to Library.');
      }else{
        ToastUtil.showMessage('Removed from Library.');
      }
      notifier.notifyListeners();
      await FileInfoDataOperate.insertFileInfo(fileInfo);
      _favoriteController.add(fileInfo);
    }
  }

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }
}