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

type authClient = {
  signIn: signIn,
  signUp: signUp,
  signOut: (~options: signOutOptions=?) => promise<response<unit>>,
  updateUser: (updateUserOptions, ~fetchOptions: fetchOptions<user>=?) => promise<response<user>>,
  useSession: unit => useSessionReturn,
  @as("$ERROR_CODES")
  errorCodes: Js.Dict.t<string>,
}

// Create auth client
@module("better-auth/react")
external createAuthClient: (~config: clientConfig<'a>=?) => authClient = "createAuthClient"

// Magic Link Plugin
@module("better-auth/client/plugins")
external magicLinkClient: unit => 'plugin = "magicLinkClient"
