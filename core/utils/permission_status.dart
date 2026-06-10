/// Permission status enum.
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unknown;

  bool get isGranted => this == granted;
  bool get isDenied => this == denied || this == permanentlyDenied;
}
