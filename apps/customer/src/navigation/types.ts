/**
 * Navigator param lists. Kept in one place so screens can type their props
 * without importing from the navigator that renders them (which would be a
 * circular import).
 */

export type RootStackParamList = {
  Auth: undefined;
  Main: undefined;
};

export type AuthStackParamList = {
  PhoneEntry: undefined;
  OtpVerify: undefined;
};

export type MainTabParamList = {
  Home: undefined;
  Search: undefined;
  Cart: undefined;
  Profile: undefined;
};
