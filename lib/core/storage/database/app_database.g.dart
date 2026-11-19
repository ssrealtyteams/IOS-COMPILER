// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LeadsTableTable extends LeadsTable
    with TableInfo<$LeadsTableTable, LeadEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeadsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _projectNameMeta =
      const VerificationMeta('projectName');
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
      'project_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _budgetMinMeta =
      const VerificationMeta('budgetMin');
  @override
  late final GeneratedColumn<double> budgetMin = GeneratedColumn<double>(
      'budget_min', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _budgetMaxMeta =
      const VerificationMeta('budgetMax');
  @override
  late final GeneratedColumn<double> budgetMax = GeneratedColumn<double>(
      'budget_max', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastActivityAtMeta =
      const VerificationMeta('lastActivityAt');
  @override
  late final GeneratedColumn<DateTime> lastActivityAt =
      GeneratedColumn<DateTime>('last_activity_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String> tags =
      GeneratedColumn<String>('tags', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>($LeadsTableTable.$convertertagsn);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fullName,
        phone,
        status,
        priority,
        source,
        createdAt,
        updatedAt,
        projectName,
        budgetMin,
        budgetMax,
        location,
        lastActivityAt,
        tags,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'leads_table';
  @override
  VerificationContext validateIntegrity(Insertable<LeadEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('project_name')) {
      context.handle(
          _projectNameMeta,
          projectName.isAcceptableOrUnknown(
              data['project_name']!, _projectNameMeta));
    }
    if (data.containsKey('budget_min')) {
      context.handle(_budgetMinMeta,
          budgetMin.isAcceptableOrUnknown(data['budget_min']!, _budgetMinMeta));
    }
    if (data.containsKey('budget_max')) {
      context.handle(_budgetMaxMeta,
          budgetMax.isAcceptableOrUnknown(data['budget_max']!, _budgetMaxMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('last_activity_at')) {
      context.handle(
          _lastActivityAtMeta,
          lastActivityAt.isAcceptableOrUnknown(
              data['last_activity_at']!, _lastActivityAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LeadEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeadEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      projectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_name']),
      budgetMin: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}budget_min']),
      budgetMax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}budget_max']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      lastActivityAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_activity_at']),
      tags: $LeadsTableTable.$convertertagsn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LeadsTableTable createAlias(String alias) {
    return $LeadsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertertags =
      const ListStringConverter();
  static TypeConverter<List<String>?, String?> $convertertagsn =
      NullAwareTypeConverter.wrap($convertertags);
}

class LeadEntity extends DataClass implements Insertable<LeadEntity> {
  final String id;
  final String fullName;
  final String phone;
  final String status;
  final String priority;
  final String source;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? projectName;
  final double? budgetMin;
  final double? budgetMax;
  final String? location;
  final DateTime? lastActivityAt;
  final List<String>? tags;
  final bool isSynced;
  const LeadEntity(
      {required this.id,
      required this.fullName,
      required this.phone,
      required this.status,
      required this.priority,
      required this.source,
      required this.createdAt,
      this.updatedAt,
      this.projectName,
      this.budgetMin,
      this.budgetMax,
      this.location,
      this.lastActivityAt,
      this.tags,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['phone'] = Variable<String>(phone);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    if (!nullToAbsent || budgetMin != null) {
      map['budget_min'] = Variable<double>(budgetMin);
    }
    if (!nullToAbsent || budgetMax != null) {
      map['budget_max'] = Variable<double>(budgetMax);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || lastActivityAt != null) {
      map['last_activity_at'] = Variable<DateTime>(lastActivityAt);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] =
          Variable<String>($LeadsTableTable.$convertertagsn.toSql(tags));
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LeadsTableCompanion toCompanion(bool nullToAbsent) {
    return LeadsTableCompanion(
      id: Value(id),
      fullName: Value(fullName),
      phone: Value(phone),
      status: Value(status),
      priority: Value(priority),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      budgetMin: budgetMin == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetMin),
      budgetMax: budgetMax == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetMax),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      lastActivityAt: lastActivityAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityAt),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      isSynced: Value(isSynced),
    );
  }

  factory LeadEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeadEntity(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phone: serializer.fromJson<String>(json['phone']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      budgetMin: serializer.fromJson<double?>(json['budgetMin']),
      budgetMax: serializer.fromJson<double?>(json['budgetMax']),
      location: serializer.fromJson<String?>(json['location']),
      lastActivityAt: serializer.fromJson<DateTime?>(json['lastActivityAt']),
      tags: serializer.fromJson<List<String>?>(json['tags']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'phone': serializer.toJson<String>(phone),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'projectName': serializer.toJson<String?>(projectName),
      'budgetMin': serializer.toJson<double?>(budgetMin),
      'budgetMax': serializer.toJson<double?>(budgetMax),
      'location': serializer.toJson<String?>(location),
      'lastActivityAt': serializer.toJson<DateTime?>(lastActivityAt),
      'tags': serializer.toJson<List<String>?>(tags),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LeadEntity copyWith(
          {String? id,
          String? fullName,
          String? phone,
          String? status,
          String? priority,
          String? source,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<String?> projectName = const Value.absent(),
          Value<double?> budgetMin = const Value.absent(),
          Value<double?> budgetMax = const Value.absent(),
          Value<String?> location = const Value.absent(),
          Value<DateTime?> lastActivityAt = const Value.absent(),
          Value<List<String>?> tags = const Value.absent(),
          bool? isSynced}) =>
      LeadEntity(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        source: source ?? this.source,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        projectName: projectName.present ? projectName.value : this.projectName,
        budgetMin: budgetMin.present ? budgetMin.value : this.budgetMin,
        budgetMax: budgetMax.present ? budgetMax.value : this.budgetMax,
        location: location.present ? location.value : this.location,
        lastActivityAt:
            lastActivityAt.present ? lastActivityAt.value : this.lastActivityAt,
        tags: tags.present ? tags.value : this.tags,
        isSynced: isSynced ?? this.isSynced,
      );
  LeadEntity copyWithCompanion(LeadsTableCompanion data) {
    return LeadEntity(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phone: data.phone.present ? data.phone.value : this.phone,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      projectName:
          data.projectName.present ? data.projectName.value : this.projectName,
      budgetMin: data.budgetMin.present ? data.budgetMin.value : this.budgetMin,
      budgetMax: data.budgetMax.present ? data.budgetMax.value : this.budgetMax,
      location: data.location.present ? data.location.value : this.location,
      lastActivityAt: data.lastActivityAt.present
          ? data.lastActivityAt.value
          : this.lastActivityAt,
      tags: data.tags.present ? data.tags.value : this.tags,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeadEntity(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('projectName: $projectName, ')
          ..write('budgetMin: $budgetMin, ')
          ..write('budgetMax: $budgetMax, ')
          ..write('location: $location, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('tags: $tags, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      fullName,
      phone,
      status,
      priority,
      source,
      createdAt,
      updatedAt,
      projectName,
      budgetMin,
      budgetMax,
      location,
      lastActivityAt,
      tags,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeadEntity &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.phone == this.phone &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.projectName == this.projectName &&
          other.budgetMin == this.budgetMin &&
          other.budgetMax == this.budgetMax &&
          other.location == this.location &&
          other.lastActivityAt == this.lastActivityAt &&
          other.tags == this.tags &&
          other.isSynced == this.isSynced);
}

class LeadsTableCompanion extends UpdateCompanion<LeadEntity> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> phone;
  final Value<String> status;
  final Value<String> priority;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<String?> projectName;
  final Value<double?> budgetMin;
  final Value<double?> budgetMax;
  final Value<String?> location;
  final Value<DateTime?> lastActivityAt;
  final Value<List<String>?> tags;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LeadsTableCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phone = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.projectName = const Value.absent(),
    this.budgetMin = const Value.absent(),
    this.budgetMax = const Value.absent(),
    this.location = const Value.absent(),
    this.lastActivityAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LeadsTableCompanion.insert({
    required String id,
    required String fullName,
    required String phone,
    required String status,
    required String priority,
    required String source,
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.projectName = const Value.absent(),
    this.budgetMin = const Value.absent(),
    this.budgetMax = const Value.absent(),
    this.location = const Value.absent(),
    this.lastActivityAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fullName = Value(fullName),
        phone = Value(phone),
        status = Value(status),
        priority = Value(priority),
        source = Value(source),
        createdAt = Value(createdAt);
  static Insertable<LeadEntity> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? phone,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? projectName,
    Expression<double>? budgetMin,
    Expression<double>? budgetMax,
    Expression<String>? location,
    Expression<DateTime>? lastActivityAt,
    Expression<String>? tags,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (projectName != null) 'project_name': projectName,
      if (budgetMin != null) 'budget_min': budgetMin,
      if (budgetMax != null) 'budget_max': budgetMax,
      if (location != null) 'location': location,
      if (lastActivityAt != null) 'last_activity_at': lastActivityAt,
      if (tags != null) 'tags': tags,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LeadsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? fullName,
      Value<String>? phone,
      Value<String>? status,
      Value<String>? priority,
      Value<String>? source,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<String?>? projectName,
      Value<double?>? budgetMin,
      Value<double?>? budgetMax,
      Value<String?>? location,
      Value<DateTime?>? lastActivityAt,
      Value<List<String>?>? tags,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LeadsTableCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      projectName: projectName ?? this.projectName,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      location: location ?? this.location,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      tags: tags ?? this.tags,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (budgetMin.present) {
      map['budget_min'] = Variable<double>(budgetMin.value);
    }
    if (budgetMax.present) {
      map['budget_max'] = Variable<double>(budgetMax.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (lastActivityAt.present) {
      map['last_activity_at'] = Variable<DateTime>(lastActivityAt.value);
    }
    if (tags.present) {
      map['tags'] =
          Variable<String>($LeadsTableTable.$convertertagsn.toSql(tags.value));
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeadsTableCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('phone: $phone, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('projectName: $projectName, ')
          ..write('budgetMin: $budgetMin, ')
          ..write('budgetMax: $budgetMax, ')
          ..write('location: $location, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('tags: $tags, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CallsTableTable extends CallsTable
    with TableInfo<$CallsTableTable, CallEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _leadIdMeta = const VerificationMeta('leadId');
  @override
  late final GeneratedColumn<String> leadId = GeneratedColumn<String>(
      'lead_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dispositionMeta =
      const VerificationMeta('disposition');
  @override
  late final GeneratedColumn<String> disposition = GeneratedColumn<String>(
      'disposition', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remarksMeta =
      const VerificationMeta('remarks');
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
      'remarks', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        leadId,
        phoneNumber,
        startTime,
        endTime,
        durationSeconds,
        status,
        direction,
        disposition,
        remarks,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calls_table';
  @override
  VerificationContext validateIntegrity(Insertable<CallEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lead_id')) {
      context.handle(_leadIdMeta,
          leadId.isAcceptableOrUnknown(data['lead_id']!, _leadIdMeta));
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    } else if (isInserting) {
      context.missing(_phoneNumberMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('disposition')) {
      context.handle(
          _dispositionMeta,
          disposition.isAcceptableOrUnknown(
              data['disposition']!, _dispositionMeta));
    }
    if (data.containsKey('remarks')) {
      context.handle(_remarksMeta,
          remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CallEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      leadId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lead_id']),
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      disposition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}disposition']),
      remarks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remarks']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $CallsTableTable createAlias(String alias) {
    return $CallsTableTable(attachedDatabase, alias);
  }
}

class CallEntity extends DataClass implements Insertable<CallEntity> {
  final String id;
  final String? leadId;
  final String phoneNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String status;
  final String direction;
  final String? disposition;
  final String? remarks;
  final bool isSynced;
  const CallEntity(
      {required this.id,
      this.leadId,
      required this.phoneNumber,
      required this.startTime,
      this.endTime,
      required this.durationSeconds,
      required this.status,
      required this.direction,
      this.disposition,
      this.remarks,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || leadId != null) {
      map['lead_id'] = Variable<String>(leadId);
    }
    map['phone_number'] = Variable<String>(phoneNumber);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['status'] = Variable<String>(status);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || disposition != null) {
      map['disposition'] = Variable<String>(disposition);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  CallsTableCompanion toCompanion(bool nullToAbsent) {
    return CallsTableCompanion(
      id: Value(id),
      leadId:
          leadId == null && nullToAbsent ? const Value.absent() : Value(leadId),
      phoneNumber: Value(phoneNumber),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationSeconds: Value(durationSeconds),
      status: Value(status),
      direction: Value(direction),
      disposition: disposition == null && nullToAbsent
          ? const Value.absent()
          : Value(disposition),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      isSynced: Value(isSynced),
    );
  }

  factory CallEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallEntity(
      id: serializer.fromJson<String>(json['id']),
      leadId: serializer.fromJson<String?>(json['leadId']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      status: serializer.fromJson<String>(json['status']),
      direction: serializer.fromJson<String>(json['direction']),
      disposition: serializer.fromJson<String?>(json['disposition']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'leadId': serializer.toJson<String?>(leadId),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'status': serializer.toJson<String>(status),
      'direction': serializer.toJson<String>(direction),
      'disposition': serializer.toJson<String?>(disposition),
      'remarks': serializer.toJson<String?>(remarks),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  CallEntity copyWith(
          {String? id,
          Value<String?> leadId = const Value.absent(),
          String? phoneNumber,
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          int? durationSeconds,
          String? status,
          String? direction,
          Value<String?> disposition = const Value.absent(),
          Value<String?> remarks = const Value.absent(),
          bool? isSynced}) =>
      CallEntity(
        id: id ?? this.id,
        leadId: leadId.present ? leadId.value : this.leadId,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        status: status ?? this.status,
        direction: direction ?? this.direction,
        disposition: disposition.present ? disposition.value : this.disposition,
        remarks: remarks.present ? remarks.value : this.remarks,
        isSynced: isSynced ?? this.isSynced,
      );
  CallEntity copyWithCompanion(CallsTableCompanion data) {
    return CallEntity(
      id: data.id.present ? data.id.value : this.id,
      leadId: data.leadId.present ? data.leadId.value : this.leadId,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      status: data.status.present ? data.status.value : this.status,
      direction: data.direction.present ? data.direction.value : this.direction,
      disposition:
          data.disposition.present ? data.disposition.value : this.disposition,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallEntity(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status, ')
          ..write('direction: $direction, ')
          ..write('disposition: $disposition, ')
          ..write('remarks: $remarks, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, leadId, phoneNumber, startTime, endTime,
      durationSeconds, status, direction, disposition, remarks, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallEntity &&
          other.id == this.id &&
          other.leadId == this.leadId &&
          other.phoneNumber == this.phoneNumber &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationSeconds == this.durationSeconds &&
          other.status == this.status &&
          other.direction == this.direction &&
          other.disposition == this.disposition &&
          other.remarks == this.remarks &&
          other.isSynced == this.isSynced);
}

class CallsTableCompanion extends UpdateCompanion<CallEntity> {
  final Value<String> id;
  final Value<String?> leadId;
  final Value<String> phoneNumber;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> durationSeconds;
  final Value<String> status;
  final Value<String> direction;
  final Value<String?> disposition;
  final Value<String?> remarks;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const CallsTableCompanion({
    this.id = const Value.absent(),
    this.leadId = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.direction = const Value.absent(),
    this.disposition = const Value.absent(),
    this.remarks = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CallsTableCompanion.insert({
    required String id,
    this.leadId = const Value.absent(),
    required String phoneNumber,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required String status,
    required String direction,
    this.disposition = const Value.absent(),
    this.remarks = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        phoneNumber = Value(phoneNumber),
        startTime = Value(startTime),
        status = Value(status),
        direction = Value(direction);
  static Insertable<CallEntity> custom({
    Expression<String>? id,
    Expression<String>? leadId,
    Expression<String>? phoneNumber,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationSeconds,
    Expression<String>? status,
    Expression<String>? direction,
    Expression<String>? disposition,
    Expression<String>? remarks,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (leadId != null) 'lead_id': leadId,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (status != null) 'status': status,
      if (direction != null) 'direction': direction,
      if (disposition != null) 'disposition': disposition,
      if (remarks != null) 'remarks': remarks,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CallsTableCompanion copyWith(
      {Value<String>? id,
      Value<String?>? leadId,
      Value<String>? phoneNumber,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<int>? durationSeconds,
      Value<String>? status,
      Value<String>? direction,
      Value<String?>? disposition,
      Value<String?>? remarks,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return CallsTableCompanion(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      disposition: disposition ?? this.disposition,
      remarks: remarks ?? this.remarks,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (leadId.present) {
      map['lead_id'] = Variable<String>(leadId.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (disposition.present) {
      map['disposition'] = Variable<String>(disposition.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallsTableCompanion(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status, ')
          ..write('direction: $direction, ')
          ..write('disposition: $disposition, ')
          ..write('remarks: $remarks, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _queuedAtMeta =
      const VerificationMeta('queuedAt');
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
      'queued_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        operation,
        payloadJson,
        queuedAt,
        retryCount,
        lastError,
        status
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(_queuedAtMeta,
          queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta));
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      queuedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}queued_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueEntity extends DataClass implements Insertable<SyncQueueEntity> {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final DateTime queuedAt;
  final int retryCount;
  final String? lastError;
  final String status;
  const SyncQueueEntity(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payloadJson,
      required this.queuedAt,
      required this.retryCount,
      this.lastError,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      queuedAt: Value(queuedAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
    );
  }

  factory SyncQueueEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntity(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncQueueEntity copyWith(
          {int? id,
          String? entityType,
          String? entityId,
          String? operation,
          String? payloadJson,
          DateTime? queuedAt,
          int? retryCount,
          Value<String?> lastError = const Value.absent(),
          String? status}) =>
      SyncQueueEntity(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payloadJson: payloadJson ?? this.payloadJson,
        queuedAt: queuedAt ?? this.queuedAt,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError.present ? lastError.value : this.lastError,
        status: status ?? this.status,
      );
  SyncQueueEntity copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueEntity(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntity(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, entityId, operation,
      payloadJson, queuedAt, retryCount, lastError, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntity &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.queuedAt == this.queuedAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.status == this.status);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueEntity> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> queuedAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<String> status;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    required DateTime queuedAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payloadJson = Value(payloadJson),
        queuedAt = Value(queuedAt);
  static Insertable<SyncQueueEntity> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? queuedAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payloadJson,
      Value<DateTime>? queuedAt,
      Value<int>? retryCount,
      Value<String?>? lastError,
      Value<String>? status}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LeadsTableTable leadsTable = $LeadsTableTable(this);
  late final $CallsTableTable callsTable = $CallsTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [leadsTable, callsTable, syncQueueTable];
}

typedef $$LeadsTableTableCreateCompanionBuilder = LeadsTableCompanion Function({
  required String id,
  required String fullName,
  required String phone,
  required String status,
  required String priority,
  required String source,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<String?> projectName,
  Value<double?> budgetMin,
  Value<double?> budgetMax,
  Value<String?> location,
  Value<DateTime?> lastActivityAt,
  Value<List<String>?> tags,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LeadsTableTableUpdateCompanionBuilder = LeadsTableCompanion Function({
  Value<String> id,
  Value<String> fullName,
  Value<String> phone,
  Value<String> status,
  Value<String> priority,
  Value<String> source,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<String?> projectName,
  Value<double?> budgetMin,
  Value<double?> budgetMax,
  Value<String?> location,
  Value<DateTime?> lastActivityAt,
  Value<List<String>?> tags,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LeadsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LeadsTableTable> {
  $$LeadsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get budgetMin => $composableBuilder(
      column: $table.budgetMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get budgetMax => $composableBuilder(
      column: $table.budgetMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastActivityAt => $composableBuilder(
      column: $table.lastActivityAt,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get tags => $composableBuilder(
          column: $table.tags,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LeadsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LeadsTableTable> {
  $$LeadsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get budgetMin => $composableBuilder(
      column: $table.budgetMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get budgetMax => $composableBuilder(
      column: $table.budgetMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastActivityAt => $composableBuilder(
      column: $table.lastActivityAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LeadsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeadsTableTable> {
  $$LeadsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => column);

  GeneratedColumn<double> get budgetMin =>
      $composableBuilder(column: $table.budgetMin, builder: (column) => column);

  GeneratedColumn<double> get budgetMax =>
      $composableBuilder(column: $table.budgetMax, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActivityAt => $composableBuilder(
      column: $table.lastActivityAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>?, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LeadsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LeadsTableTable,
    LeadEntity,
    $$LeadsTableTableFilterComposer,
    $$LeadsTableTableOrderingComposer,
    $$LeadsTableTableAnnotationComposer,
    $$LeadsTableTableCreateCompanionBuilder,
    $$LeadsTableTableUpdateCompanionBuilder,
    (LeadEntity, BaseReferences<_$AppDatabase, $LeadsTableTable, LeadEntity>),
    LeadEntity,
    PrefetchHooks Function()> {
  $$LeadsTableTableTableManager(_$AppDatabase db, $LeadsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeadsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LeadsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LeadsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String?> projectName = const Value.absent(),
            Value<double?> budgetMin = const Value.absent(),
            Value<double?> budgetMax = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<DateTime?> lastActivityAt = const Value.absent(),
            Value<List<String>?> tags = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LeadsTableCompanion(
            id: id,
            fullName: fullName,
            phone: phone,
            status: status,
            priority: priority,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt,
            projectName: projectName,
            budgetMin: budgetMin,
            budgetMax: budgetMax,
            location: location,
            lastActivityAt: lastActivityAt,
            tags: tags,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fullName,
            required String phone,
            required String status,
            required String priority,
            required String source,
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String?> projectName = const Value.absent(),
            Value<double?> budgetMin = const Value.absent(),
            Value<double?> budgetMax = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<DateTime?> lastActivityAt = const Value.absent(),
            Value<List<String>?> tags = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LeadsTableCompanion.insert(
            id: id,
            fullName: fullName,
            phone: phone,
            status: status,
            priority: priority,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt,
            projectName: projectName,
            budgetMin: budgetMin,
            budgetMax: budgetMax,
            location: location,
            lastActivityAt: lastActivityAt,
            tags: tags,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LeadsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LeadsTableTable,
    LeadEntity,
    $$LeadsTableTableFilterComposer,
    $$LeadsTableTableOrderingComposer,
    $$LeadsTableTableAnnotationComposer,
    $$LeadsTableTableCreateCompanionBuilder,
    $$LeadsTableTableUpdateCompanionBuilder,
    (LeadEntity, BaseReferences<_$AppDatabase, $LeadsTableTable, LeadEntity>),
    LeadEntity,
    PrefetchHooks Function()>;
typedef $$CallsTableTableCreateCompanionBuilder = CallsTableCompanion Function({
  required String id,
  Value<String?> leadId,
  required String phoneNumber,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<int> durationSeconds,
  required String status,
  required String direction,
  Value<String?> disposition,
  Value<String?> remarks,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$CallsTableTableUpdateCompanionBuilder = CallsTableCompanion Function({
  Value<String> id,
  Value<String?> leadId,
  Value<String> phoneNumber,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<int> durationSeconds,
  Value<String> status,
  Value<String> direction,
  Value<String?> disposition,
  Value<String?> remarks,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$CallsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CallsTableTable> {
  $$CallsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get leadId => $composableBuilder(
      column: $table.leadId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get disposition => $composableBuilder(
      column: $table.disposition, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remarks => $composableBuilder(
      column: $table.remarks, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$CallsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CallsTableTable> {
  $$CallsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get leadId => $composableBuilder(
      column: $table.leadId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get disposition => $composableBuilder(
      column: $table.disposition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remarks => $composableBuilder(
      column: $table.remarks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$CallsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallsTableTable> {
  $$CallsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get leadId =>
      $composableBuilder(column: $table.leadId, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get disposition => $composableBuilder(
      column: $table.disposition, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$CallsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CallsTableTable,
    CallEntity,
    $$CallsTableTableFilterComposer,
    $$CallsTableTableOrderingComposer,
    $$CallsTableTableAnnotationComposer,
    $$CallsTableTableCreateCompanionBuilder,
    $$CallsTableTableUpdateCompanionBuilder,
    (CallEntity, BaseReferences<_$AppDatabase, $CallsTableTable, CallEntity>),
    CallEntity,
    PrefetchHooks Function()> {
  $$CallsTableTableTableManager(_$AppDatabase db, $CallsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> leadId = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String?> disposition = const Value.absent(),
            Value<String?> remarks = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CallsTableCompanion(
            id: id,
            leadId: leadId,
            phoneNumber: phoneNumber,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            status: status,
            direction: direction,
            disposition: disposition,
            remarks: remarks,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> leadId = const Value.absent(),
            required String phoneNumber,
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            required String status,
            required String direction,
            Value<String?> disposition = const Value.absent(),
            Value<String?> remarks = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CallsTableCompanion.insert(
            id: id,
            leadId: leadId,
            phoneNumber: phoneNumber,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            status: status,
            direction: direction,
            disposition: disposition,
            remarks: remarks,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CallsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CallsTableTable,
    CallEntity,
    $$CallsTableTableFilterComposer,
    $$CallsTableTableOrderingComposer,
    $$CallsTableTableAnnotationComposer,
    $$CallsTableTableCreateCompanionBuilder,
    $$CallsTableTableUpdateCompanionBuilder,
    (CallEntity, BaseReferences<_$AppDatabase, $CallsTableTable, CallEntity>),
    CallEntity,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  required String entityType,
  required String entityId,
  required String operation,
  required String payloadJson,
  required DateTime queuedAt,
  Value<int> retryCount,
  Value<String?> lastError,
  Value<String> status,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payloadJson,
  Value<DateTime> queuedAt,
  Value<int> retryCount,
  Value<String?> lastError,
  Value<String> status,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
      column: $table.queuedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
      column: $table.queuedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueEntity,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueEntity,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueEntity>
    ),
    SyncQueueEntity,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(
      _$AppDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> queuedAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            queuedAt: queuedAt,
            retryCount: retryCount,
            lastError: lastError,
            status: status,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required String entityId,
            required String operation,
            required String payloadJson,
            required DateTime queuedAt,
            Value<int> retryCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            queuedAt: queuedAt,
            retryCount: retryCount,
            lastError: lastError,
            status: status,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueEntity,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueEntity,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueEntity>
    ),
    SyncQueueEntity,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LeadsTableTableTableManager get leadsTable =>
      $$LeadsTableTableTableManager(_db, _db.leadsTable);
  $$CallsTableTableTableManager get callsTable =>
      $$CallsTableTableTableManager(_db, _db.callsTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
}
