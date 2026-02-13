import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/reservations_providers.dart';
import '../../domain/enums/reservation_status.dart';

/// 예약 추가/수정 폼
class ReservationForm extends ConsumerStatefulWidget {
  final Reservation? reservation;

  const ReservationForm({super.key, this.reservation});

  @override
  ConsumerState<ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends ConsumerState<ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _partySizeController;
  late final TextEditingController _specialRequestsController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();

    final reservation = widget.reservation;
    if (reservation != null) {
      // 수정 모드
      _customerNameController = TextEditingController(text: reservation.customerName);
      _customerPhoneController = TextEditingController(text: reservation.customerPhone);
      _partySizeController = TextEditingController(text: '${reservation.partySize}');
      _specialRequestsController = TextEditingController(text: reservation.specialRequests ?? '');
      _selectedDate = reservation.reservationDate;
      _selectedTime = _parseTimeOfDay(reservation.reservationTime);
      _selectedStatus = reservation.status;
    } else {
      // 추가 모드
      _customerNameController = TextEditingController();
      _customerPhoneController = TextEditingController();
      _partySizeController = TextEditingController(text: '2');
      _specialRequestsController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedStatus = ReservationStatus.pending.value;
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _partySizeController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditMode = widget.reservation != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? l10n.editReservation : l10n.addReservation),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 고객명
            TextFormField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: l10n.customerName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.customerNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 연락처
            TextFormField(
              controller: _customerPhoneController,
              decoration: InputDecoration(
                labelText: l10n.customerPhone,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
                hintText: '010-1234-5678',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.customerPhoneRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 인원
            TextFormField(
              controller: _partySizeController,
              decoration: InputDecoration(
                labelText: l10n.partySize,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.people),
                suffixText: l10n.people,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.partySizeRequired;
                }
                final partySize = int.tryParse(value);
                if (partySize == null || partySize < 1) {
                  return l10n.partySizeInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 예약 날짜
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.reservationDate,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd (E)', Localizations.localeOf(context).toString()).format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 예약 시간
            InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.reservationTime,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                child: Text(
                  _formatTimeOfDay(_selectedTime),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 상태 (수정 모드일 때만)
            if (isEditMode)
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: l10n.status,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: ReservationStatus.allStatuses.map((status) {
                  final l10n = AppLocalizations.of(context)!;
                  return DropdownMenuItem(
                    value: status.value,
                    child: Row(
                      children: [
                        Icon(status.icon, color: status.color, size: 20),
                        const SizedBox(width: 8),
                        Text(_getLocalizedStatusLabel(l10n, status)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
            if (isEditMode) const SizedBox(height: 16),

            // 특이사항
            TextFormField(
              controller: _specialRequestsController,
              decoration: InputDecoration(
                labelText: l10n.specialRequestsOptional,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes),
                hintText: '예: 창가 자리 선호, 유아 의자 필요',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 저장 버튼
            ElevatedButton(
              onPressed: _saveReservation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dao = ref.read(reservationsDaoProvider);
    final customerName = _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();
    final partySize = int.parse(_partySizeController.text);
    final specialRequests = _specialRequestsController.text.trim();
    final reservationTime = _formatTimeOfDay(_selectedTime);

    try {
      if (widget.reservation == null) {
        // 추가
        await dao.createReservation(
          ReservationsCompanion.insert(
            customerName: customerName,
            customerPhone: customerPhone,
            partySize: partySize,
            reservationDate: _selectedDate,
            reservationTime: reservationTime,
            status: drift.Value(_selectedStatus),
            specialRequests: drift.Value(specialRequests.isEmpty ? null : specialRequests),
          ),
        );

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.addReservation} - ${l10n.msgSaved}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // 수정
        await dao.updateReservation(
          reservationId: widget.reservation!.id,
          customerName: customerName,
          customerPhone: customerPhone,
          partySize: partySize,
          reservationDate: _selectedDate,
          reservationTime: reservationTime,
          specialRequests: specialRequests.isEmpty ? null : specialRequests,
        );

        // 상태 변경
        if (_selectedStatus != widget.reservation!.status) {
          await dao.updateReservationStatus(
            reservationId: widget.reservation!.id,
            status: _selectedStatus,
          );
        }

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.editReservation} - ${l10n.msgSaved}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.msgError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getLocalizedStatusLabel(AppLocalizations l10n, ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return l10n.reservationPending;
      case ReservationStatus.confirmed:
        return l10n.reservationConfirmed;
      case ReservationStatus.seated:
        return l10n.reservationSeated;
      case ReservationStatus.cancelled:
        return l10n.reservationCancelled;
      case ReservationStatus.noShow:
        return l10n.reservationNoShow;
    }
  }
}
