import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address.dart';

class AddressService {
  final String userId;
  AddressService(this.userId);

  CollectionReference get _addressRef =>
      FirebaseFirestore.instance.collection('users').doc(userId).collection('addresses');

  Stream<List<Address>> getAddresses() {
    return _addressRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Address.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id})).toList());
  }

  Future<void> addAddress(Address address) async {
    await _addressRef.add(address.toJson());
  }

  Future<void> updateAddress(Address address) async {
    await _addressRef.doc(address.id).set(address.toJson());
  }

  Future<void> deleteAddress(String addressId) async {
    await _addressRef.doc(addressId).delete();
  }

  Future<DocumentReference> addAddressWithId(Address address) async {
    return await _addressRef.add(address.toJson());
  }
} 