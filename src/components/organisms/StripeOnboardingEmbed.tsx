import { useRef } from 'react'
import { loadConnectAndInitialize } from '@stripe/connect-js'
import type { StripeConnectInstance } from '@stripe/connect-js/dist/exportedTypes/shared'
import {
  ConnectComponentsProvider,
  ConnectAccountOnboarding,
} from '@stripe/react-connect-js'

interface Props {
  clientSecret: string
  onExit: () => void
}

// Module-level cache: ensures loadConnectAndInitialize (and fetchClientSecret) is
// called exactly once per clientSecret, even across React StrictMode unmount/remount cycles.
let cachedEntry: { secret: string; instance: StripeConnectInstance } | null = null

function getOrCreateInstance(clientSecret: string): StripeConnectInstance {
  if (!cachedEntry || cachedEntry.secret !== clientSecret) {
    cachedEntry = {
      secret: clientSecret,
      instance: loadConnectAndInitialize({
        publishableKey: import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY as string,
        fetchClientSecret: async () => clientSecret,
        appearance: {
          overlays: 'dialog',
          variables: {
            colorPrimary: '#a3e635',
          },
        },
      }),
    }
  }
  return cachedEntry.instance
}

export function StripeOnboardingEmbed({ clientSecret, onExit }: Props) {
  const instanceRef = useRef<StripeConnectInstance>(getOrCreateInstance(clientSecret))

  return (
    <ConnectComponentsProvider connectInstance={instanceRef.current}>
      <ConnectAccountOnboarding onExit={onExit} />
    </ConnectComponentsProvider>
  )
}
