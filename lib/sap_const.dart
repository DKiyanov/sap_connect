/// Constants used in work with SAP
library sap_const;

/// Types of SAP data
class SapType{
  static const String Date        = "D";
  static const String Time        = "T";
  static const String DecFloat    = "F";
  static const String Decimal     = "P";
  static const String Integer     = "I";
  static const String NumChar     = "N";
  static const String ShortString = "C";
  static const String string      = "g";
}

/// Boolean
class SapBool{
  static const String True  = "X";
  static const String False = "";
}

/// Range sign
class SapRangeSign{
  static const String Include = "I";
  static const String Exclude = "E";
}

/// Range option
class SapRangeOption{
  static const String Equally        = "EQ";
  static const String NotEqual       = "NE";
  static const String Less           = "LT";
  static const String LessOrEqual    = "LE";
  static const String More           = "GT";
  static const String MoreOrEqual    = "GE";
  static const String Between        = "BT";
  static const String ContainPattern = "CP";
}

/// Range fields
class SapRangeField{
  static const String Sign   = "SIGN";
  static const String Option = "OPTION";
  static const String Low    = "LOW";
  static const String High   = "HIGH";
}

/// Range
class SapRange{
  final String  sign;
  final String  option;
  final dynamic low;
  final dynamic high;

  SapRange({this.sign = SapRangeSign.Include, this.option = SapRangeOption.Equally, this.low, this.high});

  Map<String, dynamic> toJson(){
    return {
      SapRangeField.Sign   : sign,
      SapRangeField.Option : option,
      SapRangeField.Low    : low,
      SapRangeField.High   : high,
    };
  }
}
