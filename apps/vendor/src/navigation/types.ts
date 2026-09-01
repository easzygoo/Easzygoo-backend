/**
 * Navigator param lists + the top-level app state.
 *
 * Kept in one place so screens can type their props without importing from the
 * navigator that renders them (which would be a circular import).
 */

/**
 * Which of the four top-level flows the vendor sees. Currently hardcoded in
 * App.tsx; will be derived from stored auth + the Vendor row's status
 * (PENDING / APPROVED) once the API is wired up.
 */
export type VendorAppState = 'loggedOut' | 'onboarding' | 'pendingApproval' | 'active';

export type RootStackParamList = {
  Auth: undefined;
  Onboarding: undefined;
  PendingApproval: undefined;
  Main: undefined;
};

export type AuthStackParamList = {
  PhoneEntry: undefined;
  OtpVerify: undefined;
};

export type OnboardingStackParamList = {
  StoreDetails: undefined;
  BankDetails: undefined;
};

export type MainTabParamList = {
  Orders: undefined;
  Catalog: undefined;
  Earnings: undefined;
  Store: undefined;
};
