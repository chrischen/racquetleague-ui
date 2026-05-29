// Better Auth React Client Bindings

// Error types
type errorCode = string
type error = {
  message: string,
  status: int,
  statusText: string,
  code: option<errorCode>,
}

// Response types
type response<'data> = {
  data: Js.Null.t<'data>,
  error: Js.Null.t<error>,
}

// Session types
type user = {
  id: string,
  email: string,
  name: option<string>,
  image: option<string>,
  emailVerified: bool,
  createdAt: Js.Date.t,
  updatedAt: Js.Date.t,
}

type session = {
  id: string,
  userId: string,
  expiresAt: Js.Date.t,
  token: string,
  ipAddress: option<string>,
  userAgent: option<string>,
}

type sessionData = {
  user: user,
  session: session,
}

// Hook return types
type useSessionReturn = {
  data: option<sessionData>,
  isPending: bool,
  error: option<error>,
  refetch: unit => unit,
}

// Fetch options
type fetchOptions<'data> = {
  onSuccess?: 'data => unit,
  onError?: error => unit,
  disableSignal?: bool,
}

// Sign in options
type emailSignInOptions = {
  email: string,
  password: string,
  callbackURL?: string,
  fetchOptions?: fetchOptions<sessionData>,
}

type magicLinkOptions = {
  email: string,
  callbackURL?: string,
  fetchOptions?: fetchOptions<unit>,
}

type socialSignInOptions = {
  provider: string,
  callbackURL?: string,
  fetchOptions?: fetchOptions<sessionData>,
}

// Sign up options
type emailSignUpOptions = {
  email: string,
  password: string,
  name: option<string>,
  image?: string,
  callbackURL?: string,
  fetchOptions?: fetchOptions<sessionData>,
}

// Sign out options
type signOutOptions = {fetchOptions?: fetchOptions<unit>}

// Update user options
type updateUserOptions = {
  name?: string,
  image?: string,
  fetchOptions?: fetchOptions<user>,
}

// Client configuration
type clientConfig<'plugin> = {
  baseURL?: string,
  plugins?: array<'plugin>,
}

// Client type
type signIn = {
  email: (
    emailSignInOptions,
    ~fetchOptions: fetchOptions<sessionData>=?,
  ) => promise<response<sessionData>>,
  magicLink: (magicLinkOptions, ~fetchOptions: fetchOptions<unit>=?) => promise<response<unit>>,
  social: (
    socialSignInOptions,
    ~fetchOptions: fetchOptions<sessionData>=?,
  ) => promise<response<sessionData>>,
}

type signUp = {
  email: (
    emailSignUpOptions,
    ~fetchOptions: fetchOptions<sessionData>=?,
  ) => promise<response<sessionData>>,
}

type rec authClient = {
  signIn: signIn,
  signUp: signUp,
  signOut: (~options: signOutOptions=?) => promise<response<unit>>,
  updateUser: (updateUserOptions, ~fetchOptions: fetchOptions<user>=?) => promise<response<user>>,
  useSession: unit => useSessionReturn,
  device: device,
  @as("$ERROR_CODES")
  errorCodes: Js.Dict.t<string>,
}

// Device Authorization (RFC 8628) types
// Used so the PWA can sign in via an external browser when its standalone
// browser context can't complete OAuth/magic-link callbacks.
and device = {
  code: deviceCodeOptions => promise<response<deviceCodeData>>,
  token: deviceTokenOptions => promise<response<deviceTokenData>>,
  approve: deviceApprovalOptions => promise<response<unit>>,
  deny: deviceApprovalOptions => promise<response<unit>>,
}
and deviceCodeOptions = {
  client_id: string,
  scope?: string,
}
and deviceCodeData = {
  device_code: string,
  user_code: string,
  verification_uri: string,
  verification_uri_complete: option<string>,
  expires_in: int,
  interval: int,
}
and deviceTokenOptions = {
  grant_type: string,
  device_code: string,
  client_id: string,
  fetchOptions?: fetchOptions<deviceTokenData>,
}
and deviceTokenData = {
  access_token: string,
  token_type: string,
  expires_in: int,
  scope: string,
}
and deviceApprovalOptions = {userCode: string}

// Create auth client
@module("better-auth/react")
external createAuthClient: (~config: clientConfig<'a>=?) => authClient = "createAuthClient"

// Magic Link Plugin
@module("better-auth/client/plugins")
external magicLinkClient: unit => 'plugin = "magicLinkClient"

// Device Authorization Plugin (client side). Adds `authClient.device.*` methods.
@module("better-auth/client/plugins")
external deviceAuthorizationClient: unit => 'plugin = "deviceAuthorizationClient"

// Convenience: standardised grant_type for the device flow.
let deviceGrantType = "urn:ietf:params:oauth:grant-type:device_code"
