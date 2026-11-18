import 'dart:math' as math;
import 'i18n.dart';

/// '3 tonnes', '1 tonne', '2.5 tonnes'
String tonnesText(num t) {
  final s = t == t.roundToDouble() ? t.toStringAsFixed(0) : t.toStringAsFixed(1);
  return '$s ${t == 1 ? 'tonne' : 'tonnes'}';
}

double toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? toDoubleOrNull(dynamic v) => v == null ? null : toDouble(v);

int toInt(dynamic v) => toDouble(v).round();

int? toIntOrNull(dynamic v) => v == null ? null : toInt(v);

DateTime? toDate(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

List<String> toStringList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];

class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String role; // 'admin', 'manager', 'owner' (vehicle owner), 'driver' or 'passenger'
  final bool active;
  final DateTime? blockedAt; // set when the office blocked or deactivated this account
  final String? blockedReason;
  final String? truckId;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelation;
  final String language;
  final String? avatarPath; // profile picture in storage
  final String? accountId; // company monthly account (passengers)
  final int noShows; // bookings the passenger missed
  final bool drivesOwn; // an owner who also drives his own vehicle (can switch mode)

  Profile({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.active,
    this.blockedAt,
    this.blockedReason,
    this.truckId,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinRelation,
    this.language = 'en',
    this.avatarPath,
    this.accountId,
    this.noShows = 0,
    this.drivesOwn = false,
  });

  bool get isPassenger => role == 'passenger';
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';
  bool get isVehicleOwner => role == 'owner';
  bool get isDriver => role == 'driver';
  String get displayName => (fullName?.trim().isNotEmpty ?? false) ? fullName!.trim() : (email ?? 'Driver');
  String get firstName => displayName.split(' ').first;
  bool get hasName => fullName?.trim().isNotEmpty ?? false;

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        email: m['email'] as String?,
        fullName: m['full_name'] as String?,
        phone: m['phone'] as String?,
        role: (m['role'] as String?) ?? 'driver',
        active: (m['active'] as bool?) ?? false,
        blockedAt: toDate(m['blocked_at']),
        blockedReason: m['blocked_reason'] as String?,
        truckId: m['truck_id'] as String?,
        nextOfKinName: m['next_of_kin_name'] as String?,
        nextOfKinPhone: m['next_of_kin_phone'] as String?,
        nextOfKinRelation: m['next_of_kin_relation'] as String?,
        language: (m['language'] as String?) ?? 'en',
        avatarPath: m['avatar_path'] as String?,
        accountId: m['account_id'] as String?,
        noShows: toInt(m['no_shows']),
        drivesOwn: (m['drives_own'] as bool?) ?? false,
      );

  String get roleName => {
        'admin': tx('Admin'),
        'manager': tx('Manager'),
        'owner': tx('Vehicle owner'),
        'driver': tx('Driver'),
        'passenger': tx('Passenger'),
      }[role] ??
      role;
}

class VehicleCategory {
  final String id;
  final String name;
  final bool carriesPassengers;
  final bool carriesGoods;
  final int seats;
  final List<String> licenceClasses;
  final bool active;
  final double hirePerKm; // passenger hires a whole car: price per km
  final double hireMin; // smallest hire price
  final double feeWeekly; // EfuLogistix fee for owners
  final double feeMonthly;
  final double feePerTrip;
  final bool byTonnes; // goods vehicle: measured in tonnes, not seats
  final double tonnes; // starting load for this type

  VehicleCategory({
    required this.id,
    required this.name,
    required this.carriesPassengers,
    required this.carriesGoods,
    required this.seats,
    required this.licenceClasses,
    required this.active,
    this.hirePerKm = 0,
    this.hireMin = 0,
    this.feeWeekly = 0,
    this.feeMonthly = 0,
    this.feePerTrip = 0,
    this.byTonnes = false,
    this.tonnes = 0,
  });

  bool get forHire => active && hirePerKm > 0;

  /// What a hire of [km] costs: per km, never below the minimum, rounded up to K500.
  double hirePrice(double km) {
    final p = (km * hirePerKm / 500).ceil() * 500.0;
    return p < hireMin ? hireMin : p;
  }

  factory VehicleCategory.fromMap(Map<String, dynamic> m) => VehicleCategory(
        id: m['id'] as String,
        name: (m['name'] ?? '').toString(),
        carriesPassengers: (m['carries_passengers'] as bool?) ?? true,
        carriesGoods: (m['carries_goods'] as bool?) ?? true,
        seats: toInt(m['seats']),
        licenceClasses: toStringList(m['licence_classes']),
        active: (m['active'] as bool?) ?? true,
        hirePerKm: toDouble(m['hire_per_km']),
        hireMin: toDouble(m['hire_min']),
        feeWeekly: toDouble(m['fee_weekly']),
        feeMonthly: toDouble(m['fee_monthly']),
        feePerTrip: toDouble(m['fee_per_trip']),
        byTonnes: (m['by_tonnes'] as bool?) ?? false,
        tonnes: toDouble(m['tonnes']),
      );
}

class Truck {
  final String id;
  final String plate;
  final String? model;
  final bool active;
  final String? categoryId;
  final String? ownerId; // vehicle owner
  final int? seats; // this vehicle's own seats, if different from its category
  final int? currentKm;
  final int oilIntervalKm;
  final int? lastOilKm;
  final DateTime? insuranceTo;
  final DateTime? cofTo;
  final String status; // pending (sent by the owner), approved, rejected
  final String? make;
  final String? colour;
  final int? year;
  final List<String> photos;
  final String feePlan; // weekly, monthly, per_trip
  final String? reviewNote;
  final DateTime? submittedAt;
  final double? tonnes; // this vehicle's own load in tonnes (goods vehicles)
  final int? pendingSeats; // change asked by the owner, waiting for the admin
  final double? pendingTonnes;
  final DateTime? capacityRequestedAt;

  Truck({
    required this.id,
    required this.plate,
    this.model,
    required this.active,
    this.categoryId,
    this.ownerId,
    this.seats,
    this.currentKm,
    this.oilIntervalKm = 5000,
    this.lastOilKm,
    this.insuranceTo,
    this.cofTo,
    this.status = 'approved',
    this.make,
    this.colour,
    this.year,
    this.photos = const [],
    this.feePlan = 'monthly',
    this.reviewNote,
    this.submittedAt,
    this.tonnes,
    this.pendingSeats,
    this.pendingTonnes,
    this.capacityRequestedAt,
  });

  bool get capacityWaiting => capacityRequestedAt != null;
  bool get approved => status == 'approved';
  bool get pending => status == 'pending';
  bool get rejected => status == 'rejected';

  /// "white Toyota Hilux"
  String get looks => [colour, make, model].where((s) => s != null && s.trim().isNotEmpty).join(' ');

  static Map<String, String> get feePlanNames => {'weekly': tx('Weekly'), 'monthly': tx('Monthly'), 'per_trip': tx('Per trip')};

  int? get nextOilKm => lastOilKm == null ? null : lastOilKm! + oilIntervalKm;
  int? get oilLeftKm => (nextOilKm == null || currentKm == null) ? null : nextOilKm! - currentKm!;

  factory Truck.fromMap(Map<String, dynamic> m) => Truck(
        id: m['id'] as String,
        plate: m['plate'] as String,
        model: m['model'] as String?,
        active: (m['active'] as bool?) ?? true,
        categoryId: m['category_id'] as String?,
        ownerId: m['owner_id'] as String?,
        seats: toIntOrNull(m['seats']),
        currentKm: toIntOrNull(m['current_km']),
        oilIntervalKm: toIntOrNull(m['oil_interval_km']) ?? 5000,
        lastOilKm: toIntOrNull(m['last_oil_km']),
        insuranceTo: toDate(m['insurance_to']),
        cofTo: toDate(m['cof_to']),
        status: (m['status'] as String?) ?? 'approved',
        make: m['make'] as String?,
        colour: m['colour'] as String?,
        year: toIntOrNull(m['year']),
        photos: toStringList(m['photos']),
        feePlan: (m['fee_plan'] as String?) ?? 'monthly',
        reviewNote: m['review_note'] as String?,
        submittedAt: toDate(m['submitted_at']),
        tonnes: toDoubleOrNull(m['tonnes']),
        pendingSeats: toIntOrNull(m['pending_seats']),
        pendingTonnes: toDoubleOrNull(m['pending_tonnes']),
        capacityRequestedAt: toDate(m['capacity_requested_at']),
      );
}

class GoodsItem {
  final String label;
  final double amount;

  GoodsItem(this.label, this.amount);

  Map<String, dynamic> toMap() => {'label': label, 'amount': amount};

  factory GoodsItem.fromMap(Map<String, dynamic> m) => GoodsItem((m['label'] ?? '').toString(), toDouble(m['amount']));
}

List<GoodsItem> goodsFrom(dynamic raw) => raw is List
    ? raw.whereType<Map>().map((g) => GoodsItem.fromMap(Map<String, dynamic>.from(g))).toList()
    : <GoodsItem>[];

class Trip {
  final String id;
  final int tripNo;
  final String driverId;
  final String truckId;
  final String? shiftId;
  final String? routeId;
  final String pickupName;
  final double? pickupLat;
  final double? pickupLng;
  final String destName;
  final double destLat;
  final double destLng;
  final int passengers;
  final int? paxCarried;
  final double farePerPassenger;
  final List<GoodsItem> goods;
  final double goodsTotal;
  final double stopsTotal;
  final double total;
  final double? plannedKm;
  final double? actualKm;
  final int? startKm;
  final int? endKm;
  final double? gpsKm;
  final String status; // in_progress, completed, cancelled
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? cargoKg;
  final String? cargoNote;

  Trip({
    required this.id,
    required this.tripNo,
    required this.driverId,
    required this.truckId,
    this.shiftId,
    this.routeId,
    required this.pickupName,
    this.pickupLat,
    this.pickupLng,
    required this.destName,
    required this.destLat,
    required this.destLng,
    required this.passengers,
    this.paxCarried,
    required this.farePerPassenger,
    required this.goods,
    required this.goodsTotal,
    required this.stopsTotal,
    required this.total,
    this.plannedKm,
    this.actualKm,
    this.startKm,
    this.endKm,
    this.gpsKm,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.cargoKg,
    this.cargoNote,
  });

  bool get running => status == 'in_progress';
  int get carried => paxCarried ?? passengers;
  int? get odometerKm => (startKm == null || endKm == null) ? null : endKm! - startKm!;

  factory Trip.fromMap(Map<String, dynamic> m) => Trip(
        id: m['id'] as String,
        tripNo: toInt(m['trip_no']),
        driverId: m['driver_id'] as String,
        truckId: m['truck_id'] as String,
        shiftId: m['shift_id'] as String?,
        routeId: m['route_id'] as String?,
        pickupName: (m['pickup_name'] ?? '').toString(),
        pickupLat: toDoubleOrNull(m['pickup_lat']),
        pickupLng: toDoubleOrNull(m['pickup_lng']),
        destName: (m['dest_name'] ?? '').toString(),
        destLat: toDouble(m['dest_lat']),
        destLng: toDouble(m['dest_lng']),
        passengers: toInt(m['passengers']),
        paxCarried: toIntOrNull(m['pax_carried']),
        farePerPassenger: toDouble(m['fare_per_passenger']),
        goods: goodsFrom(m['goods']),
        goodsTotal: toDouble(m['goods_total']),
        stopsTotal: toDouble(m['stops_total']),
        total: toDouble(m['total']),
        plannedKm: toDoubleOrNull(m['planned_km']),
        actualKm: toDoubleOrNull(m['actual_km']),
        startKm: toIntOrNull(m['start_km']),
        endKm: toIntOrNull(m['end_km']),
        gpsKm: toDoubleOrNull(m['gps_km']),
        status: (m['status'] ?? 'in_progress').toString(),
        startedAt: toDate(m['started_at']) ?? DateTime.now(),
        endedAt: toDate(m['ended_at']),
        cargoKg: toDoubleOrNull(m['cargo_kg']),
        cargoNote: m['cargo_note'] as String?,
      );
}

class TripStop {
  final String id;
  final String tripId;
  final String? placeName;
  final double? lat;
  final double? lng;
  final int dropped;
  final int picked;
  final String? pickedTo;
  final double fareEach;
  final String? goodsOff;
  final List<GoodsItem> goodsOn;
  final double amount;
  final double? kmFromStart;
  final bool auto;
  final DateTime at;

  TripStop({
    required this.id,
    required this.tripId,
    this.placeName,
    this.lat,
    this.lng,
    required this.dropped,
    required this.picked,
    this.pickedTo,
    required this.fareEach,
    this.goodsOff,
    required this.goodsOn,
    required this.amount,
    this.kmFromStart,
    required this.auto,
    required this.at,
  });

  factory TripStop.fromMap(Map<String, dynamic> m) => TripStop(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        placeName: m['place_name'] as String?,
        lat: toDoubleOrNull(m['lat']),
        lng: toDoubleOrNull(m['lng']),
        dropped: toInt(m['dropped']),
        picked: toInt(m['picked']),
        pickedTo: m['picked_to'] as String?,
        fareEach: toDouble(m['fare_each']),
        goodsOff: m['goods_off'] as String?,
        goodsOn: goodsFrom(m['goods_on']),
        amount: toDouble(m['amount']),
        kmFromStart: toDoubleOrNull(m['km_from_start']),
        auto: (m['auto'] as bool?) ?? false,
        at: toDate(m['at']) ?? DateTime.now(),
      );
}

class TruckLocation {
  final String truckId;
  final String? driverId;
  final String? tripId;
  final double lat;
  final double lng;
  final DateTime updatedAt;

  TruckLocation({
    required this.truckId,
    this.driverId,
    this.tripId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory TruckLocation.fromMap(Map<String, dynamic> m) => TruckLocation(
        truckId: m['truck_id'] as String,
        driverId: m['driver_id'] as String?,
        tripId: m['trip_id'] as String?,
        lat: toDouble(m['lat']),
        lng: toDouble(m['lng']),
        updatedAt: toDate(m['updated_at']) ?? DateTime.now(),
      );
}

class Expense {
  final String id;
  final String truckId;
  final String createdBy;
  final String category; // fuel, repair, tyre, other
  final double? litres;
  final double amount;
  final String? note;
  final String paidBy; // driver or office
  final String? receiptPath;
  final DateTime spentAt;

  Expense({
    required this.id,
    required this.truckId,
    required this.createdBy,
    required this.category,
    this.litres,
    required this.amount,
    this.note,
    required this.paidBy,
    this.receiptPath,
    required this.spentAt,
  });

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as String,
        truckId: m['truck_id'] as String,
        createdBy: m['created_by'] as String,
        category: (m['category'] ?? 'other').toString(),
        litres: toDoubleOrNull(m['litres']),
        amount: toDouble(m['amount']),
        note: m['note'] as String?,
        paidBy: (m['paid_by'] ?? 'driver').toString(),
        receiptPath: m['receipt_path'] as String?,
        spentAt: toDate(m['spent_at']) ?? DateTime.now(),
      );
}

const expenseNames = {'fuel': 'Fuel', 'repair': 'Repair', 'tyre': 'Tyre', 'other': 'Other'};

class Shift {
  final String id;
  final String driverId;
  final String truckId;
  final String status; // on_duty, off_duty
  final DateTime startedAt;
  final int startKm;
  final DateTime? endedAt;
  final int? endKm;
  final String? endReason;
  final List<String> truckPhotos;
  final List<String> startTruckPhotos;
  final double gpsKm;
  final String review; // open, approved, flagged
  final String? reviewNote;

  Shift({
    required this.id,
    required this.driverId,
    required this.truckId,
    required this.status,
    required this.startedAt,
    required this.startKm,
    this.endedAt,
    this.endKm,
    this.endReason,
    required this.truckPhotos,
    this.startTruckPhotos = const [],
    required this.gpsKm,
    required this.review,
    this.reviewNote,
  });

  bool get onDuty => status == 'on_duty';
  int? get odometerKm => endKm == null ? null : endKm! - startKm;

  factory Shift.fromMap(Map<String, dynamic> m) => Shift(
        id: m['id'] as String,
        driverId: m['driver_id'] as String,
        truckId: m['truck_id'] as String,
        status: (m['status'] ?? 'on_duty').toString(),
        startedAt: toDate(m['started_at']) ?? DateTime.now(),
        startKm: toInt(m['start_km']),
        endedAt: toDate(m['ended_at']),
        endKm: toIntOrNull(m['end_km']),
        endReason: m['end_reason'] as String?,
        truckPhotos: toStringList(m['truck_photos']),
        startTruckPhotos: toStringList(m['start_truck_photos']),
        gpsKm: toDouble(m['gps_km']),
        review: (m['review'] ?? 'open').toString(),
        reviewNote: m['review_note'] as String?,
      );
}

class Reading {
  final String id;
  final String? shiftId;
  final String? tripId;
  final String driverId;
  final String truckId;
  final String kind;
  final int km;
  final String? photoPath;
  final double? gpsSinceLastKm;
  final int? expectedKm;
  final bool mismatch;
  final DateTime takenAt;

  Reading({
    required this.id,
    this.shiftId,
    this.tripId,
    required this.driverId,
    required this.truckId,
    required this.kind,
    required this.km,
    this.photoPath,
    this.gpsSinceLastKm,
    this.expectedKm,
    required this.mismatch,
    required this.takenAt,
  });

  static Map<String, String> get kindNames => {
    'shift_start': tx('On duty'),
    'trip_start': tx('Trip start'),
    'trip_end': tx('Offload'),
    'shift_end': tx('Truck dropped'),
    'change_out': tx('Left truck'),
    'change_in': tx('Took truck'),
  };

  String get kindName => kindNames[kind] ?? kind;

  factory Reading.fromMap(Map<String, dynamic> m) => Reading(
        id: m['id'] as String,
        shiftId: m['shift_id'] as String?,
        tripId: m['trip_id'] as String?,
        driverId: m['driver_id'] as String,
        truckId: m['truck_id'] as String,
        kind: (m['kind'] ?? '').toString(),
        km: toInt(m['km']),
        photoPath: m['photo_path'] as String?,
        gpsSinceLastKm: toDoubleOrNull(m['gps_since_last_km']),
        expectedKm: toIntOrNull(m['expected_km']),
        mismatch: (m['mismatch'] as bool?) ?? false,
        takenAt: toDate(m['taken_at']) ?? DateTime.now(),
      );
}

class RouteFare {
  final String id;
  final String fromName;
  final String toName;
  final double? toLat;
  final double? toLng;
  final double? km;
  final double fare;
  final bool active;
  final String? categoryId; // null = any vehicle
  final String? corridorId; // set when the route belongs to a road with depots
  final bool through; // the whole road, first depot to last depot

  RouteFare({
    required this.id,
    required this.fromName,
    required this.toName,
    this.toLat,
    this.toLng,
    this.km,
    required this.fare,
    required this.active,
    this.categoryId,
    this.corridorId,
    this.through = false,
  });

  factory RouteFare.fromMap(Map<String, dynamic> m) => RouteFare(
        id: m['id'] as String,
        fromName: (m['from_name'] ?? '').toString(),
        toName: (m['to_name'] ?? '').toString(),
        toLat: toDoubleOrNull(m['to_lat']),
        toLng: toDoubleOrNull(m['to_lng']),
        km: toDoubleOrNull(m['km']),
        fare: toDouble(m['fare']),
        active: (m['active'] as bool?) ?? true,
        categoryId: m['category_id'] as String?,
        corridorId: m['corridor_id'] as String?,
        through: (m['through'] as bool?) ?? false,
      );
}

class GoodsPrice {
  final String id;
  final String label;
  final double price;
  final double perKm; // 0 = one flat price
  final bool active;

  GoodsPrice({required this.id, required this.label, required this.price, this.perKm = 0, required this.active});

  /// Base price + per km x km, rounded up to K50; a flat price when no rate is set or the distance is unknown.
  double priceFor(double? km) => perKm > 0 && km != null && km > 0 ? ((price + perKm * km) / 50).ceil() * 50.0 : price;

  factory GoodsPrice.fromMap(Map<String, dynamic> m) => GoodsPrice(
        id: m['id'] as String,
        label: (m['label'] ?? '').toString(),
        price: toDouble(m['price']),
        perKm: toDouble(m['per_km']),
        active: (m['active'] as bool?) ?? true,
      );
}

class TruckChange {
  final String id;
  final String driverId;
  final String fromTruck;
  final String toTruck;
  final String reason;
  final String? note;
  final int outKm;
  final String outPhoto;
  final String? parkedAt;
  final int inKm;
  final String inPhoto;
  final List<String> inTruckPhotos;
  final String status; // pending, approved, declined
  final DateTime createdAt;

  TruckChange({
    required this.id,
    required this.driverId,
    required this.fromTruck,
    required this.toTruck,
    required this.reason,
    this.note,
    required this.outKm,
    required this.outPhoto,
    this.parkedAt,
    required this.inKm,
    required this.inPhoto,
    required this.inTruckPhotos,
    required this.status,
    required this.createdAt,
  });

  factory TruckChange.fromMap(Map<String, dynamic> m) => TruckChange(
        id: m['id'] as String,
        driverId: m['driver_id'] as String,
        fromTruck: m['from_truck'] as String,
        toTruck: m['to_truck'] as String,
        reason: (m['reason'] ?? '').toString(),
        note: m['note'] as String?,
        outKm: toInt(m['out_km']),
        outPhoto: (m['out_photo'] ?? '').toString(),
        parkedAt: m['parked_at'] as String?,
        inKm: toInt(m['in_km']),
        inPhoto: (m['in_photo'] ?? '').toString(),
        inTruckPhotos: toStringList(m['in_truck_photos']),
        status: (m['status'] ?? 'pending').toString(),
        createdAt: toDate(m['created_at']) ?? DateTime.now(),
      );
}

class HandIn {
  final String id;
  final String shiftId;
  final String driverId;
  final String truckId;
  final DateTime day;
  final int trips;
  final int passengers;
  final double collected;
  final double driverExpenses;
  final double expected;
  final String method; // cash, airtel_money, tnm_mpamba
  final String? reference;
  final double? received;
  final DateTime? receivedAt;
  final String? note;
  final String? decision;

  HandIn({
    required this.id,
    required this.shiftId,
    required this.driverId,
    required this.truckId,
    required this.day,
    required this.trips,
    required this.passengers,
    required this.collected,
    required this.driverExpenses,
    required this.expected,
    required this.method,
    this.reference,
    this.received,
    this.receivedAt,
    this.note,
    this.decision,
  });

  bool get waiting => received == null;
  double get short => received == null ? 0 : (expected - received!).clamp(0, double.infinity).toDouble();

  static Map<String, String> get methodNames => {'cash': tx('Cash'), 'airtel_money': tx('Airtel Money'), 'tnm_mpamba': tx('TNM Mpamba')};
  String get methodName => methodNames[method] ?? method;

  factory HandIn.fromMap(Map<String, dynamic> m) => HandIn(
        id: m['id'] as String,
        shiftId: m['shift_id'] as String,
        driverId: m['driver_id'] as String,
        truckId: m['truck_id'] as String,
        day: toDate(m['day']) ?? DateTime.now(),
        trips: toInt(m['trips']),
        passengers: toInt(m['passengers']),
        collected: toDouble(m['collected']),
        driverExpenses: toDouble(m['driver_expenses']),
        expected: toDouble(m['expected']),
        method: (m['method'] ?? 'cash').toString(),
        reference: m['reference'] as String?,
        received: toDoubleOrNull(m['received']),
        receivedAt: toDate(m['received_at']),
        note: m['note'] as String?,
        decision: m['decision'] as String?,
      );
}

class AppAlert {
  final String id;
  final String kind;
  final String? truckId;
  final String? driverId;
  final String? tripId;
  final String? shiftId;
  final String? refId;
  final String title;
  final String? detail;
  final bool seen;
  final bool resolved;
  final DateTime createdAt;

  AppAlert({
    required this.id,
    required this.kind,
    this.truckId,
    this.driverId,
    this.tripId,
    this.shiftId,
    this.refId,
    required this.title,
    this.detail,
    required this.seen,
    required this.resolved,
    required this.createdAt,
  });

  factory AppAlert.fromMap(Map<String, dynamic> m) => AppAlert(
        id: m['id'] as String,
        kind: (m['kind'] ?? '').toString(),
        truckId: m['truck_id'] as String?,
        driverId: m['driver_id'] as String?,
        tripId: m['trip_id'] as String?,
        shiftId: m['shift_id'] as String?,
        refId: m['ref_id'] as String?,
        title: (m['title'] ?? '').toString(),
        detail: m['detail'] as String?,
        seen: (m['seen'] as bool?) ?? false,
        resolved: (m['resolved'] as bool?) ?? false,
        createdAt: toDate(m['created_at']) ?? DateTime.now(),
      );
}

class Doc {
  final String id;
  final String? driverId;
  final String? truckId;
  final String kind;
  final String? frontPath;
  final String? backPath;
  final String? number;
  final String? licenceClass;
  final DateTime? expiresOn;
  final String status; // pending, approved, rejected
  final String? note;
  final DateTime createdAt;

  Doc({
    required this.id,
    this.driverId,
    this.truckId,
    required this.kind,
    this.frontPath,
    this.backPath,
    this.number,
    this.licenceClass,
    this.expiresOn,
    required this.status,
    this.note,
    required this.createdAt,
  });

  bool get expired => expiresOn != null && expiresOn!.isBefore(DateTime.now());

  factory Doc.fromMap(Map<String, dynamic> m) => Doc(
        id: m['id'] as String,
        driverId: m['driver_id'] as String?,
        truckId: m['truck_id'] as String?,
        kind: (m['kind'] ?? 'other').toString(),
        frontPath: m['front_path'] as String?,
        backPath: m['back_path'] as String?,
        number: m['number'] as String?,
        licenceClass: m['licence_class'] as String?,
        expiresOn: toDate(m['expires_on']),
        status: (m['status'] ?? 'pending').toString(),
        note: m['note'] as String?,
        createdAt: toDate(m['created_at']) ?? DateTime.now(),
      );
}

/// What each driver document is, whether it needs a back side and an expiry date.
class DocKind {
  final String key;
  final String name;
  final String help;
  final bool required;
  final bool hasBack;
  final bool hasExpiry;
  final bool selfie;
  const DocKind(this.key, this.name, this.help,
      {this.required = false, this.hasBack = false, this.hasExpiry = false, this.selfie = false});
}

const driverDocKinds = [
  DocKind('national_id', 'National ID', 'Malawi National ID card, front and back', required: true, hasBack: true),
  DocKind('licence', 'Driving licence', 'Front and back, with class and expiry date',
      required: true, hasBack: true, hasExpiry: true),
  DocKind('selfie', 'Face photo', 'A clear photo of your face, taken now', required: true, selfie: true),
  DocKind('prdp', 'Professional Driving Permit (PrDP)', 'Passenger category, from DRTSS', hasExpiry: true),
  DocKind('police_clearance', 'Police clearance report', 'Recommended'),
  DocKind('residence_letter', 'Letter from chief or employer', 'Confirms where you live'),
  DocKind('defensive_driving', 'Defensive driving certificate', 'Recommended'),
];

const docNames = {
  'national_id': 'National ID',
  'licence': 'Driving licence',
  'selfie': 'Face photo',
  'prdp': 'PrDP',
  'police_clearance': 'Police clearance',
  'residence_letter': 'Chief/employer letter',
  'defensive_driving': 'Defensive driving',
  'insurance': 'Insurance',
  'cof': 'COF',
  'blue_book': 'Blue book',
  'road_tax': 'Road tax',
  'other': 'Other',
  'next_of_kin': 'Next of kin',
  'licence_class': 'Licence class for your vehicle',
};

/// Papers an owner sends with a vehicle.
const truckDocKinds = [
  DocKind('blue_book', 'Blue book (registration)', 'Photo of the registration page', required: true),
  DocKind('insurance', 'Insurance', 'Certificate with the end date', required: true, hasExpiry: true),
  DocKind('cof', 'Certificate of fitness (COF)', 'From DRTSS, with the end date', required: true, hasExpiry: true),
  DocKind('road_tax', 'Road tax', 'Receipt or disc', hasExpiry: true),
];

Map<String, String> get payNames => {
  'cash': tx('Cash to driver'),
  'airtel_money': tx('Airtel Money'),
  'tnm_mpamba': tx('TNM Mpamba'),
  'account': tx('Company account'),
};

/// A timetable departure on a route (passengers book seats on it).
class Departure {
  final String id;
  final String routeId;
  final String leavesAt; // "10:00:00"
  final List<int> days; // 1 = Monday ... 7 = Sunday
  final int? seats;
  final bool active;

  Departure({required this.id, required this.routeId, required this.leavesAt, required this.days, this.seats, this.active = true});

  /// "10:00"
  String get time => leavesAt.length >= 5 ? leavesAt.substring(0, 5) : leavesAt;
  bool runsOn(DateTime day) => days.contains(day.weekday);

  /// The departure time on [day], local time.
  DateTime leavingOn(DateTime day) {
    final parts = leavesAt.split(':');
    return DateTime(day.year, day.month, day.day, int.tryParse(parts[0]) ?? 0, int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
  }

  factory Departure.fromMap(Map<String, dynamic> m) => Departure(
        id: m['id'] as String,
        routeId: m['route_id'] as String,
        leavesAt: (m['leaves_at'] ?? '00:00:00').toString(),
        days: m['days'] is List ? (m['days'] as List).map(toInt).toList() : const [1, 2, 3, 4, 5, 6, 7],
        seats: toIntOrNull(m['seats']),
        active: (m['active'] as bool?) ?? true,
      );
}

class BookedGoods {
  final String label;
  final int qty;
  final double price;
  BookedGoods(this.label, this.qty, this.price);
  factory BookedGoods.fromMap(Map<String, dynamic> m) =>
      BookedGoods((m['label'] ?? '').toString(), toInt(m['qty']), toDouble(m['price']));
}

class Booking {
  final String id;
  final int bookingNo;
  final String? passengerId;
  final String? callerName;
  final String? callerPhone;
  final String kind; // seat, hire, goods
  final String? categoryId;
  final String? routeId;
  final String? departureId;
  final DateTime? travelOn;
  final DateTime pickupAt;
  final int seats;
  final String pickupName;
  final double? pickupLat;
  final double? pickupLng;
  final String destName;
  final double? destLat;
  final double? destLng;
  final String? tripType; // one_way, return, whole_day
  final double? km;
  final double? ratePerKm;
  final List<BookedGoods> goods;
  final String? receiverName;
  final String? receiverPhone;
  final double price;
  final double? finalPrice;
  final String payMethod;
  final String? payReference;
  final String? note;
  final String status; // requested, assigned, picked_up, completed, cancelled, no_show, declined
  final String? truckId;
  final String? driverId;
  final String? message;
  final DateTime? assignedAt;
  final DateTime? arrivedAt;
  final int deliveryTries; // parcel: times the receiver was not reached
  final DateTime? deliveryFailAt;
  final String? relayState; // waiting: handed over by another driver, the code is still to be typed
  final double? relayShare;
  final double relayFirstCash; // cash driver 1 already took for his part
  final String? deliveryChoice; // what the sender chose after a failed try: try_again / return_me / office
  final String? goodsSize; // small, medium, large
  final bool fragile;
  final double? declaredValue;
  final String? goodsPhoto;
  final String? deliveryPhoto;
  final String? cancelReason;
  final String? transferNote; // set when this booking is one part of a trip with a change of car
  final int leg; // 0 = normal, 1 or 2 = part of a trip with a change
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.bookingNo,
    this.passengerId,
    this.callerName,
    this.callerPhone,
    required this.kind,
    this.categoryId,
    this.routeId,
    this.departureId,
    this.travelOn,
    required this.pickupAt,
    required this.seats,
    required this.pickupName,
    this.pickupLat,
    this.pickupLng,
    required this.destName,
    this.destLat,
    this.destLng,
    this.tripType,
    this.km,
    this.ratePerKm,
    required this.goods,
    this.receiverName,
    this.receiverPhone,
    required this.price,
    this.finalPrice,
    required this.payMethod,
    this.payReference,
    this.note,
    required this.status,
    this.truckId,
    this.driverId,
    this.message,
    this.assignedAt,
    this.cancelReason,
    this.transferNote,
    this.leg = 0,
    required this.createdAt,
    this.arrivedAt,
    this.deliveryTries = 0,
    this.deliveryFailAt,
    this.deliveryChoice,
    this.relayState,
    this.relayShare,
    this.relayFirstCash = 0,
    this.goodsSize,
    this.fragile = false,
    this.declaredValue,
    this.goodsPhoto,
    this.deliveryPhoto,
  });

  bool get open => status == 'requested' || status == 'assigned' || status == 'picked_up';
  bool get canCancel => status == 'requested' || status == 'assigned';
  double get amount => math.max((finalPrice ?? price) - relayFirstCash, 0);
  String get payName => payNames[payMethod] ?? payMethod;
  String get goodsText => goods.map((g) => '${g.qty} × ${g.label}').join(', ');

  static Map<String, String> get statusNames => {
    'requested': tx('Finding a car'),
    'assigned': tx('Assigned ✓'),
    'picked_up': tx('On board'),
    'completed': tx('Done'),
    'cancelled': tx('Cancelled'),
    'no_show': tx('Missed'),
    'declined': tx('Not possible'),
    'failed': tx('Trip stopped'),
  };
  String get statusName => statusNames[status] ?? status;

  static Map<String, String> get tripTypeNames => {'one_way': tx('One way'), 'return': tx('Return'), 'whole_day': tx('Whole day')};

  /// "Mangochi Main Rank → Monkey Bay" or "4 × bag of maize → Monkey Bay"
  String get title => switch (kind) {
        'goods' => '$goodsText → $destName',
        'hire' => '$pickupName → $destName${tripType == 'return' ? tx(' (return)') : tripType == 'whole_day' ? tx(' (whole day)') : ''}',
        _ => '$pickupName → $destName',
      };

  factory Booking.fromMap(Map<String, dynamic> m) => Booking(
        id: m['id'] as String,
        bookingNo: toInt(m['booking_no']),
        passengerId: m['passenger_id'] as String?,
        callerName: m['caller_name'] as String?,
        callerPhone: m['caller_phone'] as String?,
        kind: (m['kind'] ?? 'seat').toString(),
        categoryId: m['category_id'] as String?,
        routeId: m['route_id'] as String?,
        departureId: m['departure_id'] as String?,
        travelOn: toDate(m['travel_on']),
        pickupAt: toDate(m['pickup_at']) ?? DateTime.now(),
        seats: toInt(m['seats']),
        pickupName: (m['pickup_name'] ?? '').toString(),
        pickupLat: toDoubleOrNull(m['pickup_lat']),
        pickupLng: toDoubleOrNull(m['pickup_lng']),
        destName: (m['dest_name'] ?? '').toString(),
        destLat: toDoubleOrNull(m['dest_lat']),
        destLng: toDoubleOrNull(m['dest_lng']),
        tripType: m['trip_type'] as String?,
        km: toDoubleOrNull(m['km']),
        ratePerKm: toDoubleOrNull(m['rate_per_km']),
        goods: m['goods'] is List
            ? (m['goods'] as List).whereType<Map>().map((g) => BookedGoods.fromMap(Map<String, dynamic>.from(g))).toList()
            : <BookedGoods>[],
        receiverName: m['receiver_name'] as String?,
        receiverPhone: m['receiver_phone'] as String?,
        price: toDouble(m['price']),
        finalPrice: toDoubleOrNull(m['final_price']),
        payMethod: (m['pay_method'] ?? 'cash').toString(),
        payReference: m['pay_reference'] as String?,
        note: m['note'] as String?,
        status: (m['status'] ?? 'requested').toString(),
        truckId: m['truck_id'] as String?,
        driverId: m['driver_id'] as String?,
        message: m['message'] as String?,
        assignedAt: toDate(m['assigned_at']),
        arrivedAt: toDate(m['arrived_at']),
        deliveryTries: (m['delivery_tries'] as num?)?.toInt() ?? 0,
        deliveryFailAt: toDate(m['delivery_fail_at']),
        deliveryChoice: m['delivery_choice'] as String?,
        relayState: m['relay_state'] as String?,
        relayShare: m['relay_share'] == null ? null : toDouble(m['relay_share']),
        relayFirstCash: toDouble(m['relay_first_cash']),
        goodsSize: m['goods_size'] as String?,
        fragile: m['fragile'] == true,
        declaredValue: (m['declared_value'] as num?)?.toDouble(),
        goodsPhoto: m['goods_photo'] as String?,
        deliveryPhoto: m['delivery_photo'] as String?,
        cancelReason: m['cancel_reason'] as String?,
        transferNote: m['transfer_note'] as String?,
        leg: toInt(m['leg']),
        createdAt: toDate(m['created_at']) ?? DateTime.now(),
      );
}

/// A message to one person (shown under the bell).
class Notice {
  final String id;
  final String title;
  final String? body;
  final String? kind;
  final String? refId;
  final bool read;
  final bool ring; // urgent: rings like a call
  final DateTime createdAt;
  Notice({required this.id, required this.title, this.body, this.kind, this.refId, required this.read, this.ring = true, required this.createdAt});
  factory Notice.fromMap(Map<String, dynamic> m) => Notice(
        id: m['id'] as String,
        title: (m['title'] ?? '').toString(),
        body: m['body'] as String?,
        kind: m['kind'] as String?,
        refId: m['ref_id'] as String?,
        read: (m['read'] as bool?) ?? false,
        ring: (m['ring'] as bool?) ?? true,
        createdAt: toDate(m['created_at']) ?? DateTime.now(),
      );
}

/// Driver and vehicle owner invited to meet at the office.
class DriverMatch {
  final String id;
  final String driverId;
  final String truckId;
  final DateTime meetAt;
  final String place;
  final String status; // invited, agreed, not_agreed, cancelled
  final String? note;
  final DateTime createdAt;
  DriverMatch({
    required this.id,
    required this.driverId,
    required this.truckId,
    required this.meetAt,
    required this.place,
    required this.status,
    this.note,
    required this.createdAt,
  });
  factory DriverMatch.fromMap(Map<String, dynamic> m) => DriverMatch(
        id: m['id'] as String,
        driverId: m['driver_id'] as String,
        truckId: m['truck_id'] as String,
        meetAt: toDate(m['meet_at']) ?? DateTime.now(),
        place: (m['place'] ?? '').toString(),
        status: (m['status'] ?? 'invited').toString(),
        note: m['note'] as String?,
        createdAt: toDate(m['created_at']) ?? DateTime.now(),
      );
}

/// One line in a driver's wallet: earned (+), taken off (−) or paid out (−).
class WalletEntry {
  final String id;
  final String driverId;
  final String? ownerId;
  final String? handInId;
  final String kind; // earn, deduct, payout
  final double amount;
  final DateTime day;
  final String? method;
  final String? reference;
  final String? note;
  final DateTime createdAt;
  WalletEntry({
    required this.id,
    required this.driverId,
    this.ownerId,
    this.handInId,
    required this.kind,
    required this.amount,
    required this.day,
    this.method,
    this.reference,
    this.note,
    required this.createdAt,
  });
  factory WalletEntry.fromMap(Map<String, dynamic> m) => WalletEntry(
        id: m['id'] as String,
        driverId: m['driver_id'] as String,
        ownerId: m['owner_id'] as String?,
        handInId: m['hand_in_id'] as String?,
        kind: (m['kind'] ?? 'earn').toString(),
        amount: toDouble(m['amount']),
        day: toDate(m['day']) ?? DateTime.now(),
        method: m['method'] as String?,
        reference: m['reference'] as String?,
        note: m['note'] as String?,
        createdAt: toDate(m['created_at']) ?? DateTime.now(),
      );
}

/// EfuLogistix fee bill for one vehicle and one period.
class FeeBill {
  final String id;
  final String truckId;
  final String? ownerId;
  final String plan;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int trips;
  final double amount;
  final String status; // due, paid, waived
  final String? method;
  final String? reference;
  final DateTime? reportedAt;
  final DateTime? paidAt;
  FeeBill({
    required this.id,
    required this.truckId,
    this.ownerId,
    required this.plan,
    required this.periodStart,
    required this.periodEnd,
    required this.trips,
    required this.amount,
    required this.status,
    this.method,
    this.reference,
    this.reportedAt,
    this.paidAt,
  });
  bool get due => status == 'due';
  factory FeeBill.fromMap(Map<String, dynamic> m) => FeeBill(
        id: m['id'] as String,
        truckId: m['truck_id'] as String,
        ownerId: m['owner_id'] as String?,
        plan: (m['plan'] ?? 'monthly').toString(),
        periodStart: toDate(m['period_start']) ?? DateTime.now(),
        periodEnd: toDate(m['period_end']) ?? DateTime.now(),
        trips: toInt(m['trips']),
        amount: toDouble(m['amount']),
        status: (m['status'] ?? 'due').toString(),
        method: m['method'] as String?,
        reference: m['reference'] as String?,
        reportedAt: toDate(m['reported_at']),
        paidAt: toDate(m['paid_at']),
      );
}

class CompanyAccount {
  final String id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final bool active;
  CompanyAccount({required this.id, required this.name, this.contactName, this.phone, this.email, this.active = true});
  factory CompanyAccount.fromMap(Map<String, dynamic> m) => CompanyAccount(
        id: m['id'] as String,
        name: (m['name'] ?? '').toString(),
        contactName: m['contact_name'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        active: (m['active'] as bool?) ?? true,
      );
}

/// One saved GPS point of a vehicle's day.
class GpsPoint {
  final double lat;
  final double lng;
  final double speed; // m/s
  final DateTime at;
  final String? tripId;
  GpsPoint(this.lat, this.lng, this.speed, this.at, this.tripId);
  double get kmh => speed * 3.6;
  factory GpsPoint.fromMap(Map<String, dynamic> m) => GpsPoint(
        toDouble(m['lat']),
        toDouble(m['lng']),
        toDouble(m['speed']),
        toDate(m['at']) ?? DateTime.now(),
        m['trip_id'] as String?,
      );
}
