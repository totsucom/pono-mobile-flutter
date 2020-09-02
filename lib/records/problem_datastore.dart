
//problemsコレクションを扱うツール
class ProblemDatastore {
  //Firestoreのコレクション名を返す
  static String getCollectionPath() {
    return "problems";
  }

  //Firestoreのドキュメントパスを返す
  static String getDocumentPath(String documentId) {
    return "problems/$documentId";
  }
/*
  //problemを追加する
  //成功時にDocumentIDを返す
  static Future<String> addProblem(Problem problem, UI.Image basePicture, UI.Image completedImage) async {
    var completer = new Completer<String>();
    try {
      final storageResult = await ProblemBasePictureStorage.upload(basePicture);


      

    var map = problem.toMap();
    //作成日を追加する
    map[ProblemField.createdAt] = FieldValue.serverTimestamp();
    map.remove(ProblemField.updatedAt);
    final newDocument = Firestore.instance.collection(getCollectionPath())
        .document();
    newDocument.setData(map);
    return newDocument.documentID;
  }
  static void addProblemT(Transaction transaction, Problem problem) {
    final Map map = problem.toMap();
    //作成日を追加する
    map[ProblemField.createdAt] = FieldValue.serverTimestamp();
    map.remove(ProblemField.updatedAt);
    transaction.set(
        Firestore.instance.collection(getCollectionPath()).document(), map);
  }

  //userを更新する
  static void updateProblem(String documentID, Problem problem) {
    final Map map = problem.toMap();
    //更新日を変更する
    map[ProblemField.updatedAt] = FieldValue.serverTimestamp();
    map.remove(ProblemField.createdAt);
    Firestore.instance.collection(getCollectionPath()).document(documentID)
        .setData(map);
  }
  static void updateProblemT(Transaction transaction, String documentID,
      Problem problem) {
    final Map map = problem.toMap();
    //更新日を変更する
    map[ProblemField.updatedAt] = FieldValue.serverTimestamp();
    map.remove(ProblemField.createdAt);
    transaction.update(Firestore.instance.collection(getCollectionPath())
        .document(documentID), map);
  }

  //problemを取得する
  //documentIDが存在しない場合はnullを返す
  static Future<Problem> getProblem(String documentID) async {
    final snapshot = await Firestore.instance
        .document(getDocumentPath(documentID)).get();
    return snapshot.exists ? Problem.fromMap(snapshot.data) : null;
  }
  static Future<Problem> getProblemT(Transaction transaction,
      String documentID) async {
    final snapshot = await transaction
        .get(Firestore.instance.document(getDocumentPath(documentID)));
    return snapshot.exists ? Problem.fromMap(snapshot.data) : null;
  }

  //problemを削除する
  static void deleteProblem(String documentID) {
    Firestore.instance.document(getDocumentPath(documentID)).delete();
  }
*/
}
