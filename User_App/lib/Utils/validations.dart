class Validations {
  validateNumber({String? v}) {
    if (v!.trim().isEmpty) {
      return 'Please Enter Valid Number';
    } else if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
      return 'Please enter Numbers only';
    } else if (v.trim().length != 10) {
      return "Number Should Be 10 Digits";
    }
    return null;
  }

  bool isValidGSTNumber(String? value) {
    if (value != null) {
      value = value.trim(); // Trim leading and trailing whitespaces
      if (value.isNotEmpty) {
        if (value.length == 15) {
          return true;
        }
        String gstNumberPattern =
            r'^[0-9]{2}[A-Za-z]{5}[0-9]{4}[A-Za-z]{1}[1-9A-Za-z]{1}[Zz]{1}[0-9A-Za-z]{1}$';
        RegExp regex = RegExp(gstNumberPattern);
        return regex.hasMatch(value);
      }
    }
    return false;
  }

  bool validateFirstCharacterIsLetter(String input) {
    // Check if the first character is a letter (i.e., a string)
    if (input.isNotEmpty) {
      final firstCharacter = input[0];
      if (RegExp(r'[a-zA-Z0-9]').hasMatch(firstCharacter)) {
        // The first character is a letter, which is valid
        return true;
      }
    } else {
      return true;
    }

    // The first character is not a letter (a digit or special character)
    return false;
  }
}

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

// extension EmailValidator on String {
//   bool isValidEmail() {
//     return RegExp(
//       r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
//     ).hasMatch(this);
//   }
// }
