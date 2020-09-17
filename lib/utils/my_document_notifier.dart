import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

enum MyDocumentNotifyReason { None, Created, Changed, Deleted }

// Firestoreのドキュメントを監視するクラス
class MyDocumentNotifier extends ChangeNotifier {
  // Notifyの理由を返す。処理したらresetすること
  MyDocumentNotifyReason _reason = MyDocumentNotifyReason.None;
  MyDocumentNotifyReason get reason => _reason;
  void resetReason() {
    _reason = MyDocumentNotifyReason.None;
  }

  bool _exist; //現在ドキュメントは存在するか?

  DocumentSnapshot _snapshot;
  DocumentSnapshot get snapshot => _snapshot;

  StreamSubscription<DocumentSnapshot> _streamSubscription;

  MyDocumentNotifier(String documentPath, bool documentExist) {
    _exist = documentExist;
    _streamSubscription = Firestore.instance
        .document(documentPath)
        .snapshots()
        .listen((DocumentSnapshot documentSnapshot) {
      if (!_exist && documentSnapshot.data == null) {
        // 削除された
        _snapshot = null;
        _exist = false;
        _reason = MyDocumentNotifyReason.Deleted;
        notifyListeners();
      } else if (!_exist && documentSnapshot.data != null) {
        // 登録された
        _snapshot = documentSnapshot;
        _exist = true;
        _reason = MyDocumentNotifyReason.Created;
        notifyListeners();
      } else if (_exist && documentSnapshot.data != null) {
        // 更新された
        _snapshot = documentSnapshot;
        _exist = true;
        _reason = MyDocumentNotifyReason.Changed;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    if (_streamSubscription != null) _streamSubscription.cancel();
    super.dispose();
  }
}
