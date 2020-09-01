import 'package:flutter/material.dart';

class MenuItem<T> {
  final String title;
  final Icon icon;
  final T value;
  MenuItem(this.value, {this.title, this.icon});

  BottomNavigationBarItem toBottomNavigationBarItem() {
    return BottomNavigationBarItem(
      icon: this.icon,
      title: (this.title != null) ? Text(this.title) : null,
    );
  }

  PopupMenuEntry<T> toPopupMenuItem() {
    if (this.title != null) {
      if (this.icon != null) {
        return PopupMenuItem<T>(
            value: this.value,
            child: ListTile(leading: this.icon, title: Text(this.title)));
      } else {
        return PopupMenuItem<T>(value: this.value, child: Text(this.title));
      }
    } else {
      if (this.icon != null) {
        return PopupMenuItem<T>(value: this.value, child: this.icon);
      } else {
        throw Exception('titleまたはiconが必要');
      }
    }
  }

  DropdownMenuItem<T> toDropdownMenuItem() {
    if (this.title != null) {
      if (this.icon != null) {
        return DropdownMenuItem<T>(
            value: this.value,
            child: ListTile(leading: this.icon, title: Text(this.title)));
      } else {
        return DropdownMenuItem<T>(value: this.value, child: Text(this.title));
      }
    } else {
      if (this.icon != null) {
        return DropdownMenuItem<T>(value: this.value, child: this.icon);
      } else {
        throw Exception('titleまたはiconが必要');
      }
    }
  }
}

/*class ColorMenuItem {
  final Color color;
  ColorMenuItem(this.color);

  DropdownMenuItem<Color> toDropdownMenuItem() {
    return DropdownMenuItem<Color>(
        value: this.color, child: Icon(Icons.stop, color: this.color));
  }
}
*/
