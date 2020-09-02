class Conv {
  //Firestoreにdoubleで0.0を書き込んでも 0として読み出されるため、
  //double <= int 代入でエラーになる。
  //そういうものを回避
  static toDbl(value, {nullValue = 0.0, errorValue}) {
    if (value == null) return nullValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return errorValue;
  }
}
