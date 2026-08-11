# Task: Final Analysis Clean-up

- [ ] Fix syntax and logic issues
    - [ ] `extractNIN.dart`: Fix interpolation
    - [ ] `extractunknown.dart`: Fix interpolation
    - [ ] `newcaptureidcard.dart`: Update `withOpacity` to `withValues`
    - [ ] `newfacepage.dart`: Remove unused import
    - [ ] `newinputpage.dart`: Fix BuildContext async gap
- [ ] Rename files and update imports
    - [ ] `example/lib/String.dart` -> `example/lib/string_extensions.dart`
    - [ ] `lib/models/IDCardInfo.dart` -> `lib/models/id_card_info.dart`
    - [ ] `lib/models/extractDriverLicense.dart` -> `lib/models/extract_driver_license.dart`
    - [ ] `lib/models/extractNIN.dart` -> `lib/models/extract_nin.dart`
    - [ ] `lib/models/extractVoter.dart` -> `lib/models/extract_voter.dart`
    - [ ] `lib/models/nin/digitalNINslip.dart` -> `lib/models/nin/digital_nin_slip.dart`
- [ ] Verify with `dart analyze`
