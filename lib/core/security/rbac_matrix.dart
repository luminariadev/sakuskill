enum UserRole {
  client,
  provider,
  campusAdmin,
}

enum AppPermission {
  serviceCreate,
  serviceOrder,
  orderSubmitWork,
  orderReleaseFunds,
  orderDispute,
  barterPropose,
  barterSubmit,
  barterApprove,
  disputeResolve,
  adminAccess,
}

class RbacMatrix {
  static const Map<UserRole, Set<AppPermission>> rolePermissions = {
    UserRole.client: {
      AppPermission.serviceOrder,
      AppPermission.orderReleaseFunds,
      AppPermission.orderDispute,
      AppPermission.barterPropose,
      AppPermission.barterApprove,
    },
    UserRole.provider: {
      AppPermission.serviceCreate,
      AppPermission.serviceOrder,
      AppPermission.orderSubmitWork,
      AppPermission.orderReleaseFunds,
      AppPermission.orderDispute,
      AppPermission.barterPropose,
      AppPermission.barterSubmit,
      AppPermission.barterApprove,
    },
    UserRole.campusAdmin: {
      AppPermission.disputeResolve,
      AppPermission.adminAccess,
    },
  };

  static bool hasPermission(UserRole role, AppPermission permission) {
    final permissions = rolePermissions[role];
    return permissions?.contains(permission) ?? false;
  }

  static String getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'Mahasiswa (Klien)';
      case UserRole.provider:
        return 'Mahasiswa (Penyedia)';
      case UserRole.campusAdmin:
        return 'Komite Etik Kampus (Admin)';
    }
  }
}
