import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/utils/toast_util.dart';

class FavoriteGroupController with ChangeNotifier{
  static final StreamController<FileGroup> _favoriteController = StreamController.broadcast();
  static Stream<FileGroup> get favoriteStream => _favoriteController.stream;

  late ValueNotifier<FileGroup> notifier;

  late StreamSubscription _favoriteSubscription;
  FavoriteGroupController({required FileGroup fileGroup}){
    notifier = ValueNotifier(fileGroup);
    _favoriteSubscription = favoriteStream.listen((musicGroup){
      if(musicGroup.id == notifier.value.id){
        notifier.value.isFavorite = musicGroup.isFavorite;
        notifier.notifyListeners();
      }
    });
  }

  void infoChange({bool isEditName=false}) async {
    FileGroup musicGroup = notifier.value;
    if(isEditName) {
      musicGroup.isFavorite = 1;
    }else{
      musicGroup.isFavorite ^= 1;
    }
    notifier.notifyListeners();
    if(musicGroup.isFavorite == 1){
      ToastUtil.showMessage('Added to Library.');
      String likeString = '"name":"${musicGroup.name}"';
      List<FileGroup> exitList = await FileGroupDataOperate.queryFileGroup(where: 'json_content LIKE \'%$likeString%\'');
      if(exitList.isNotEmpty){
        musicGroup.displayName = '${musicGroup.name}(${exitList.length})';
      }else{
        musicGroup.displayName = musicGroup.name;
      }
      await FileGroupDataOperate.insertFileGroup(musicGroup);
    }else{
      ToastUtil.showMessage('Removed from Library.');
      await FileGroupDataOperate.deleteFileGroup(musicGroup);
    }
    _favoriteController.add(musicGroup);
  }

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }
}