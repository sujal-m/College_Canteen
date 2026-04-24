part of '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;
  File? _localPhotoFile;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (xfile == null) return;
    final file = File(xfile.path);
    setState(() {
      _uploading = true;
      _localPhotoFile = file;
    });
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final savedPath = await LocalProfilePhotoStore.savePhoto(uid, file);
      await context.read<AuthProvider>().setLocalPhotoPath(uid, savedPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile photo updated.'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile upload failed: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final uid = context.read<AuthProvider>().user!.uid;
    setState(() => _uploading = true);
    try {
      await LocalProfilePhotoStore.clear(uid);
      // Also clear from Firestore if there was a remote URL stored
      await FirebaseService.updateUserDoc(uid, {'photoUrl': null});
      await context.read<AuthProvider>().setLocalPhotoPath(uid, null);
      if (!mounted) return;
      setState(() => _localPhotoFile = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile photo removed.'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to remove photo: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoOptions() {
    final localPhotoPath = context.read<AuthProvider>().localPhotoPath;
    final hasPhoto = _localPhotoFile != null ||
        localPhotoPath != null ||
        context.read<AuthProvider>().user?.photoUrl != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Profile Photo',
              style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
            ),
            title: Text(hasPhoto ? 'Change Photo' : 'Upload Photo',
                style: const TextStyle(
                    fontFamily: 'Lato', fontWeight: FontWeight.w600)),
            subtitle: const Text('Choose from your gallery',
                style: TextStyle(fontFamily: 'Lato')),
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadPhoto();
            },
          ),
          if (hasPhoto)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
              title: const Text('Remove Photo',
                  style: TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w600,
                      color: AppColors.error)),
              subtitle: const Text('Revert to default avatar',
                  style: TextStyle(fontFamily: 'Lato')),
              onTap: () async {
                Navigator.pop(context);
                // Ask for confirmation before removing
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Remove Photo'),
                    content: const Text(
                        'Are you sure you want to remove your profile photo?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remove')),
                    ],
                  ),
                );
                if (confirmed == true) _removePhoto();
              },
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style:
                    TextStyle(color: AppColors.textMuted, fontFamily: 'Lato')),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final localPhotoPath = context.watch<AuthProvider>().localPhotoPath;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: user == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: user)),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          GestureDetector(
            onTap: _uploading ? null : _showPhotoOptions,
            child: Stack(children: [
              CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: _localPhotoFile != null
                      ? FileImage(_localPhotoFile!) as ImageProvider
                      : localPhotoPath != null
                          ? FileImage(File(localPhotoPath)) as ImageProvider
                          : user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!) as ImageProvider
                              : null,
                  child: _localPhotoFile == null &&
                          localPhotoPath == null &&
                          user?.photoUrl == null
                      ? const Icon(Icons.person,
                          size: 56, color: AppColors.primary)
                      : null),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: _uploading ? Colors.grey : AppColors.primary,
                          shape: BoxShape.circle),
                      child: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.edit,
                              size: 16, color: Colors.white))),
            ]),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to change or remove photo',
            style:
                AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          _ProfileRow('Name', user?.fullName ?? '—'),
          _ProfileRow('Email', user?.email ?? '—'),
          if (user?.ucid != null) _ProfileRow('UCID', user!.ucid!),
          _ProfileRow('Gender', user?.gender ?? '—'),
          _ProfileRow('Branch', user?.branch ?? '—'),
          if (user?.classYear != null) _ProfileRow('Class', user!.classYear!),
          if (user?.division != null) _ProfileRow('Division', user!.division!),
          if (user?.designation != null)
            _ProfileRow('Designation', user!.designation!),
          const SizedBox(height: 32),
          const _Footer(),
        ]),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Lato')),
        ]),
      );
}

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _designationCtrl;
  String? _gender;
  String? _branch;
  String? _classYear;
  String? _division;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _designationCtrl =
        TextEditingController(text: widget.user.designation ?? '');
    _gender = widget.user.gender;
    _branch = widget.user.branch;
    _classYear = widget.user.classYear;
    _division = widget.user.division;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'fullName': _nameCtrl.text.trim(),
      'gender': _gender,
      'branch': _branch,
      'classYear': widget.user.role == 'student' ? _classYear : null,
      'division': widget.user.role == 'student' ? _division : null,
      'designation':
          widget.user.role == 'faculty' ? _designationCtrl.text.trim() : null,
    };
    await FirebaseService.updateUserDoc(widget.user.uid, data);
    await context.read<AuthProvider>().loadUser(widget.user.uid);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => Validators.required(v, 'Full Name'),
                  ),
                  const SizedBox(height: 14),
                  _DropdownField<String>(
                    label: 'Gender',
                    prefixIcon: Icons.wc,
                    value: _gender,
                    items: _genderOptions,
                    onChanged: (v) => setState(() => _gender = v),
                    validator: (_) => _gender == null ? 'Select gender' : null,
                  ),
                  const SizedBox(height: 14),
                  _DropdownField<String>(
                    label: 'Branch',
                    prefixIcon: Icons.school_outlined,
                    value: _branch,
                    items: _branchOptions,
                    onChanged: (v) => setState(() {
                      _branch = v;
                      if (widget.user.role == 'student' &&
                          !classOptionsForBranch(_branch)
                              .contains(_classYear)) {
                        _classYear = null;
                      }
                    }),
                    validator: (_) => _branch == null ? 'Select branch' : null,
                  ),
                  if (widget.user.role == 'student') ...[
                    const SizedBox(height: 14),
                    _DropdownField<String>(
                      label: 'Class / Year',
                      prefixIcon: Icons.class_outlined,
                      value: _classYear,
                      items: classOptionsForBranch(_branch),
                      onChanged: (v) => setState(() => _classYear = v),
                      validator: (_) =>
                          _classYear == null ? 'Select class' : null,
                    ),
                    const SizedBox(height: 14),
                    _DropdownField<String>(
                      label: 'Division',
                      prefixIcon: Icons.group_outlined,
                      value: _division,
                      items: _divisionOptions,
                      onChanged: (v) => setState(() => _division = v),
                      validator: (_) =>
                          _division == null ? 'Select division' : null,
                    ),
                    const SizedBox(height: 4),
                    const Text('Select A if you are in the only division.',
                        style: AppTextStyles.labelSmall),
                  ],
                  if (widget.user.role == 'faculty') ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _designationCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Designation',
                          prefixIcon: Icon(Icons.work_outline)),
                      validator: (v) => Validators.required(v, 'Designation'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _saving
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ElevatedButton(
                          onPressed: _save, child: const Text('Save Changes')),
                ]),
          ),
        ),
      );
}
