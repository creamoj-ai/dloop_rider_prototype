import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/tokens.dart';
import '../../services/biometric_service.dart';
import '../../services/preferences_service.dart';
import '../../services/push_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _orderSounds = true;
  bool _biometricLock = true;
  bool _biometricAvailable = false;
  String _distanceUnit = 'km';
  String? _userEmail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = Supabase.instance.client.auth.currentUser;
    final bioAvailable = await BiometricService.isAvailable();

    // Load real settings from Supabase
    RiderSettings settings;
    try {
      settings = await PreferencesService.getSettings();
    } catch (_) {
      settings = RiderSettings.defaults();
    }

    if (mounted) {
      setState(() {
        _userEmail = user?.email;
        _biometricAvailable = bioAvailable;
        _pushNotifications = settings.pushNotifications;
        _orderSounds = settings.orderSounds;
        _biometricLock = settings.biometricLock;
        _distanceUnit = settings.distanceUnit;
        _loading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await PreferencesService.updateSetting(key, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore salvataggio: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() => _pushNotifications = value);
    await _updateSetting('push_notifications', value);

    // Enable/disable FCM token
    try {
      if (value) {
        await PushNotificationService.saveFcmToken();
      } else {
        await PushNotificationService.removeToken();
      }
    } catch (_) {}
  }

  Future<void> _toggleOrderSounds(bool value) async {
    setState(() => _orderSounds = value);
    await _updateSetting('order_sounds', value);
  }

  Future<void> _toggleBiometricLock(bool value) async {
    setState(() => _biometricLock = value);
    await _updateSetting('biometric_lock', value);
  }

  Future<void> _changeDistanceUnit(String value) async {
    setState(() => _distanceUnit = value);
    await _updateSetting('distance_unit', value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Impostazioni', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.turboOrange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account section
                _sectionHeader('Account'),
                _infoTile(cs, Icons.email_outlined, 'Email', _userEmail ?? '...'),
                _actionTile(cs, Icons.lock_outline, 'Cambia password', () => _showChangePassword(context)),
                const SizedBox(height: 24),

                // Notifications section
                _sectionHeader('Notifiche'),
                _switchTile(cs, Icons.notifications_outlined, 'Notifiche push', 'Ordini, guadagni, traguardi', _pushNotifications, _togglePushNotifications),
                _switchTile(cs, Icons.volume_up_outlined, 'Suoni ordini', 'Suono per nuovi ordini', _orderSounds, _toggleOrderSounds),
                const SizedBox(height: 24),

                // Security section
                _sectionHeader('Sicurezza'),
                if (_biometricAvailable)
                  _switchTile(cs, Icons.fingerprint, 'Blocco biometrico', 'Richiedi impronta all\'apertura', _biometricLock, _toggleBiometricLock),
                if (!_biometricAvailable)
                  _infoTile(cs, Icons.fingerprint, 'Biometria', 'Non disponibile su questo dispositivo'),
                const SizedBox(height: 24),

                // Preferences section
                _sectionHeader('Preferenze'),
                _choiceTile(cs, Icons.straighten, 'Unità distanza', _distanceUnit == 'km' ? 'Chilometri' : 'Miglia', () {
                  _showDistanceUnitPicker(context);
                }),
                _infoTile(cs, Icons.language, 'Lingua', 'Italiano'),
                _infoTile(cs, Icons.dark_mode, 'Tema', 'Scuro'),
                const SizedBox(height: 24),

                // Info section
                _sectionHeader('Informazioni'),
                _actionTile(cs, Icons.description_outlined, 'Termini di servizio', () {
                  _showInfoSheet(context, 'Termini di Servizio', 'I termini di servizio completi saranno disponibili a breve.');
                }),
                _actionTile(cs, Icons.privacy_tip_outlined, 'Privacy Policy', () {
                  _showInfoSheet(context, 'Privacy Policy', 'La privacy policy completa sarà disponibile a breve.');
                }),
                _actionTile(cs, Icons.info_outline, 'Info app', () {
                  _showAppInfo(context);
                }),
                const SizedBox(height: 32),

                // Version
                Center(
                  child: Text(
                    'dloop rider v1.0.0',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.turboOrange,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _switchTile(ColorScheme cs, IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.turboOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.turboOrange, size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.turboOrange,
        ),
      ),
    );
  }

  Widget _infoTile(ColorScheme cs, IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.turboOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.turboOrange, size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        trailing: Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
      ),
    );
  }

  Widget _actionTile(ColorScheme cs, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.turboOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.turboOrange, size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _choiceTile(ColorScheme cs, IconData icon, String title, String current, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.turboOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.turboOrange, size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current, style: GoogleFonts.inter(fontSize: 13, color: AppColors.turboOrange)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final emailController = TextEditingController(text: _userEmail);
    bool isSending = false;
    bool sent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(
                  sent ? Icons.mark_email_read : Icons.lock_reset,
                  size: 40,
                  color: sent ? AppColors.earningsGreen : AppColors.turboOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  sent ? 'Link inviato!' : 'Cambia password',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  sent
                      ? 'Controlla la tua email per il link di reset.'
                      : 'Ti invieremo un link per reimpostare la password.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                if (!sent)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              setModalState(() => isSending = true);
                              try {
                                await Supabase.instance.client.auth.resetPasswordForEmail(
                                  emailController.text.trim(),
                                );
                                setModalState(() {
                                  sent = true;
                                  isSending = false;
                                });
                              } catch (_) {
                                setModalState(() => isSending = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.turboOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSending
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : Text('INVIA LINK RESET', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.earningsGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('FATTO', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDistanceUnitPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unità distanza', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 16),
            _unitOption('km', 'Chilometri (km)'),
            _unitOption('mi', 'Miglia (mi)'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _unitOption(String value, String label) {
    final selected = _distanceUnit == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? AppColors.turboOrange : Colors.white38,
      ),
      title: Text(label, style: GoogleFonts.inter(fontSize: 15, color: Colors.white)),
      onTap: () {
        _changeDistanceUnit(value);
        Navigator.pop(context);
      },
    );
  }

  void _showInfoSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 16),
            Text(body, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.turboOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bolt, size: 36, color: AppColors.turboOrange),
            ),
            const SizedBox(height: 16),
            Text('dloop rider', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Versione 1.0.0 (build 1)', style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
            const SizedBox(height: 16),
            Text(
              'App per rider dloop.\nConsegne smart, guadagni massimizzati.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
