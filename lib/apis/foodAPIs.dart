import 'package:canteen_food_ordering_app/models/food.dart';
import 'package:canteen_food_ordering_app/models/user.dart';
import 'package:canteen_food_ordering_app/notifiers/authNotifier.dart';
import 'package:canteen_food_ordering_app/screens/adminHome.dart';
import 'package:canteen_food_ordering_app/screens/login.dart';
import 'package:canteen_food_ordering_app/screens/navigationBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

late ProgressDialog pr;

void toast(String data) {
  Fluttertoast.showToast(
      msg: data,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey,
      textColor: Colors.white);
}

login(User user, AuthNotifier authNotifier, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  firebase.UserCredential authResult;
  try {
    authResult = await firebase.FirebaseAuth.instance
        .signInWithEmailAndPassword(email: user.email, password: user.password);
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }

  try {
    if (authResult != null) {
      firebase.User firebaseUser = authResult.user!;
      if (!firebaseUser.emailVerified) {
        await firebase.FirebaseAuth.instance.signOut();
        pr.hide().then((isHidden) {
          print(isHidden);
        });
        toast("Email ID not verified");
        return;
      } else if (firebaseUser != null) {
        print("Log In: $firebaseUser");
        authNotifier.setUser(firebaseUser);
        await getUserDetails(authNotifier);
        print("done");
        pr.hide().then((isHidden) {
          print(isHidden);
        });
        if (authNotifier.userDetails.role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (BuildContext context) {
              return AdminHomePage();
            }),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (BuildContext context) {
              return NavigationBarPage(selectedIndex: 1);
            }),
          );
        }
      }
    }
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }
}

signUp(User user, AuthNotifier authNotifier, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  bool userDataUploaded = false;
  firebase.UserCredential authResult;
  try {
    authResult = await firebase.FirebaseAuth.instance
        .createUserWithEmailAndPassword(
            email: user.email.trim(), password: user.password);
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }

  try {
    if (authResult != null) {
      // UserUpdateInfo updateInfo = UserUpdateInfo();
      // updateInfo.displayName = user.displayName;

      firebase.User firebaseUser = authResult.user!;
      await firebaseUser.sendEmailVerification();

      if (firebaseUser != null) {
        await firebaseUser.updateProfile(displayName: user.displayName);
        await firebaseUser.reload();
        print("Sign Up: $firebaseUser");
        uploadUserData(user, userDataUploaded);
        await firebase.FirebaseAuth.instance.signOut();
        authNotifier.setUser(firebaseUser);
        pr.hide().then((isHidden) {
          print(isHidden);
        });
        toast("Verification link is sent to ${user.email}");
        Navigator.pop(context);
      }
    }
    pr.hide().then((isHidden) {
      print(isHidden);
    });
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }
}

getUserDetails(AuthNotifier authNotifier) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(authNotifier.user.uid)
      .get()
      .catchError((e) => print(e))
      .then((value) => {
            (value != null)
                ? authNotifier.setUserDetails(User.fromMap(value.data()!))
                : print(value)
          });
}

uploadUserData(User user, bool userdataUpload) async {
  bool userDataUploadVar = userdataUpload;
  firebase.User currentUser = await firebase.FirebaseAuth.instance.currentUser!;

  CollectionReference userRef = FirebaseFirestore.instance.collection('users');
  CollectionReference cartRef = FirebaseFirestore.instance.collection('carts');

  user.uuid = currentUser.uid;
  if (userDataUploadVar != true) {
    await userRef
        .doc(currentUser.uid)
        .set(user.toMap())
        .catchError((e) => print(e))
        .then((value) => userDataUploadVar = true);
    await cartRef
        .doc(currentUser.uid)
        .set({})
        .catchError((e) => print(e))
        .then((value) => userDataUploadVar = true);
  } else {
    print('already uploaded user data');
  }
  print('user data uploaded successfully');
}

initializeCurrentUser(AuthNotifier authNotifier, BuildContext context) async {
  firebase.User? firebaseUser =
      await firebase.FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    authNotifier.setUser(firebaseUser);
    await getUserDetails(authNotifier);
  }
}

signOut(AuthNotifier authNotifier, BuildContext context) async {
  await firebase.FirebaseAuth.instance.signOut();

  // authNotifier.setUser(null);
  print('log out');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (BuildContext context) {
      return LoginPage();
    }),
  );
}

forgotPassword(
    User user, AuthNotifier authNotifier, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    await firebase.FirebaseAuth.instance
        .sendPasswordResetEmail(email: user.email);
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  toast("Reset Email has sent successfully");
  Navigator.pop(context);
}

addToCart(Food food, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    firebase.User currentUser =
        await firebase.FirebaseAuth.instance.currentUser!;
    CollectionReference cartRef =
        FirebaseFirestore.instance.collection('carts');
    QuerySnapshot data =
        await cartRef.doc(currentUser.uid).collection('items').get();
    if (data.docs.length >= 10) {
      pr.hide().then((isHidden) {
        print(isHidden);
      });
      toast("Cart cannot have more than 10 times!");
      return;
    }
    await cartRef
        .doc(currentUser.uid)
        .collection('items')
        .doc(food.id)
        .set({"count": 1})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to add to cart!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  toast("Added to cart successfully!");
}

removeFromCart(Food food, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    firebase.User currentUser =
        await firebase.FirebaseAuth.instance.currentUser!;
    CollectionReference cartRef =
        FirebaseFirestore.instance.collection('carts');
    await cartRef
        .doc(currentUser.uid)
        .collection('items')
        .doc(food.id)
        .delete()
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to Remove from cart!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  toast("Removed from cart successfully!");
}

addNewItem(
    String? itemName, int? price, int? totalQty, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference itemRef =
        FirebaseFirestore.instance.collection('items');
    await itemRef
        .doc()
        .set({"item_name": itemName, "price": price, "total_qty": totalQty})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to add to new item!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  toast("New Item added successfully!");
}

editItem(String itemName, int price, int totalQty, BuildContext context,
    String id) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference itemRef =
        FirebaseFirestore.instance.collection('items');
    await itemRef
        .doc(id)
        .set({"item_name": itemName, "price": price, "total_qty": totalQty})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to edit item!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  toast("Item edited successfully!");
}

deleteItem(String id, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference itemRef =
        FirebaseFirestore.instance.collection('items');
    await itemRef
        .doc(id)
        .delete()
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to edit item!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  toast("Item edited successfully!");
}

editCartItem(String itemId, int count, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    firebase.User currentUser =
        await firebase.FirebaseAuth.instance.currentUser!;
    CollectionReference cartRef =
        FirebaseFirestore.instance.collection('carts');
    if (count <= 0) {
      await cartRef
          .doc(currentUser.uid)
          .collection('items')
          .doc(itemId)
          .delete()
          .catchError((e) => print(e))
          .then((value) => print("Success"));
    } else {
      await cartRef
          .doc(currentUser.uid)
          .collection('items')
          .doc(itemId)
          .update({"count": count})
          .catchError((e) => print(e))
          .then((value) => print("Success"));
    }
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to update Cart!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  toast("Cart updated successfully!");
}

addMoney(int amount, BuildContext context, String id) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference userRef =
        FirebaseFirestore.instance.collection('users');
    await userRef
        .doc(id)
        .update({'balance': FieldValue.increment(amount)})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to add money!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (BuildContext context) {
      return NavigationBarPage(selectedIndex: 1);
    }),
  );
  toast("Money added successfully!");
}

placeOrder(BuildContext context, double total) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    // Initiaization
    firebase.User currentUser =
        await firebase.FirebaseAuth.instance.currentUser!;
    CollectionReference cartRef =
        FirebaseFirestore.instance.collection('carts');
    CollectionReference orderRef =
        FirebaseFirestore.instance.collection('orders');
    CollectionReference itemRef =
        FirebaseFirestore.instance.collection('items');
    CollectionReference userRef =
        FirebaseFirestore.instance.collection('users');

    List<String> foodIds = [];
    Map<String, int> count = new Map<String, int>();
    List<dynamic> _cartItems = [];

    // Checking user balance
    DocumentSnapshot userData = await userRef.doc(currentUser.uid).get();

    var uData = userData.data() as Map<String, dynamic>;
    if (uData['balance'] < total) {
      pr.hide().then((isHidden) {
        print(isHidden);
      });
      toast("You dont have succifient balance to place this order!");
      return;
    }

    // Getting all cart items of the user
    QuerySnapshot data =
        await cartRef.doc(currentUser.uid).collection('items').get();
    data.docs.forEach((item) {
      foodIds.add(item.id);
      var itemData = item.data() as Map<String, dynamic>;
      count[item.id] = itemData['count'];
    });

    // Checking for item availability
    QuerySnapshot snap =
        await itemRef.where(FieldPath.documentId, whereIn: foodIds).get();
    for (var i = 0; i < snap.docs.length; i++) {
      var snapData = snap.docs[i].data() as Map<String, dynamic>;
      if (snapData['total_qty'] < count[snap.docs[i].id]) {
        pr.hide().then((isHidden) {
          print(isHidden);
        });
        print("not");
        var snapData = snap.docs[i].data() as Map<String, dynamic>;

        toast(
            "Item: $snapData['item_name']} has QTY: $snapData['total_qty']} only. Reduce/Remove the item.");
        return;
      }
    }

    // Creating cart items array
    snap.docs.forEach((item) {
      var itemData = item.data() as Map<String, dynamic>;

      _cartItems.add({
        "item_id": item.id,
        "count": count[item.id],
        "item_name": itemData['item_name'],
        "price": itemData['price']
      });
    });

    // Creating a transaction
    await FirebaseFirestore.instance
        .runTransaction((Transaction transaction) async {
      // Update the item count in items table
      for (var i = 0; i < snap.docs.length; i++) {
        var snapData = snap.docs[i].data() as Map<String, dynamic>;

        await transaction.update(snap.docs[i].reference,
            {"total_qty": snapData["total_qty"] - count[snap.docs[i].id]});
      }

      // Deduct amount from user
      await userRef
          .doc(currentUser.uid)
          .update({'balance': FieldValue.increment(-1 * total)});

      // Place a new order
      await orderRef.doc().set({
        "items": _cartItems,
        "is_delivered": false,
        "total": total,
        "placed_at": DateTime.now(),
        "placed_by": currentUser.uid
      });

      // Empty cart
      for (var i = 0; i < data.docs.length; i++) {
        await transaction.delete(data.docs[i].reference);
      }
      print("in in");
      // return;
    });

    // Successfull transaction
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) {
        return NavigationBarPage(selectedIndex: 1);
      }),
    );
    toast("Order Placed Successfully!");
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    Navigator.pop(context);
    toast("Failed to place order!");
    print(error);
    return;
  }
}

orderReceived(String id, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference ordersRef =
        FirebaseFirestore.instance.collection('orders');
    await ordersRef
        .doc(id)
        .update({'is_delivered': true})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to mark as received!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  toast("Order received successfully!");
}
