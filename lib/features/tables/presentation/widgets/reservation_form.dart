import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
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
    final isEditMode = widget.reservation != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '예약 수정' : '예약 추가'),
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
              decoration: const InputDecoration(
                labelText: '고객명',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '고객명을 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 연락처
            TextFormField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(
                labelText: '연락처',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '010-1234-5678',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '연락처를 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 인원
            TextFormField(
              controller: _partySizeController,
              decoration: const InputDecoration(
                labelText: '인원',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
                suffixText: '명',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '인원을 입력하세요';
                }
                final partySize = int.tryParse(value);
                if (partySize == null || partySize < 1) {
                  return '1명 이상 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 예약 날짜
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '예약 날짜',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd (E)', 'ko_KR').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 예약 시간
            InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '예약 시간',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
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
                decoration: const InputDecoration(
                  labelText: '상태',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: ReservationStatus.allStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status.value,
                    child: Row(
                      children: [
                        Icon(status.icon, color: status.color, size: 20),
                        const SizedBox(width: 8),
                        Text(status.label),
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
              decoration: const InputDecoration(
                labelText: '특이사항 (선택)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
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
              child: Text(isEditMode ? '수정' : '추가'),
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
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('예약이 추가되었습니다'),
              duration: Duration(seconds: 2),
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
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('예약이 수정되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
