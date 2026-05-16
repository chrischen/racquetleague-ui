import { useState, useMemo, FormEvent } from 'react'
import { loadStripe } from '@stripe/stripe-js'
import {
  Elements,
  PaymentElement,
  useStripe,
  useElements,
} from '@stripe/react-stripe-js'

interface CheckoutFormProps {
  onSuccess: (paymentIntentId: string) => void
  onClose: () => void
}

function CheckoutForm({ onSuccess, onClose }: CheckoutFormProps) {
  const stripe = useStripe()
  const elements = useElements()
  const [error, setError] = useState<string | null>(null)
  const [processing, setProcessing] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    if (!stripe || !elements) return
    setProcessing(true)
    setError(null)

    const result = await stripe.confirmPayment({
      elements,
      redirect: 'if_required',
    })

    if (result.error) {
      setError(result.error.message ?? 'Payment failed')
      setProcessing(false)
    } else if (result.paymentIntent) {
      onSuccess(result.paymentIntent.id)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <PaymentElement />
      {error && (
        <p className="mt-2 text-sm text-red-500 dark:text-red-400">{error}</p>
      )}
      <div className="flex gap-3 justify-end pt-2">
        <button
          type="button"
          onClick={onClose}
          disabled={processing}
          className="px-4 py-2 text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white disabled:opacity-50 transition-colors"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={!stripe || processing}
          className="px-4 py-2 text-sm font-semibold rounded-md bg-amber-500 text-white hover:bg-amber-600 disabled:opacity-60 inline-flex items-center gap-1.5 transition-colors"
        >
          {processing ? 'Processing…' : 'Pay now'}
        </button>
      </div>
    </form>
  )
}

interface Props {
  clientSecret: string
  stripeAccountId: string
  onSuccess: (paymentIntentId: string) => void
  onClose: () => void
}

export function StripePaymentEmbed({ clientSecret, stripeAccountId, onSuccess, onClose }: Props) {
  const stripePromise = useMemo(
    () => loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY as string, { stripeAccount: stripeAccountId }),
    [stripeAccountId],
  )
  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose()
      }}
    >
      <div className="w-full max-w-md bg-white dark:bg-[#1e1f23] rounded-t-2xl sm:rounded-2xl p-6 shadow-xl">
        <h2 className="text-base font-semibold text-gray-900 dark:text-white mb-5">
          Complete payment
        </h2>
        <Elements
          stripe={stripePromise}
          options={{
            clientSecret,
            appearance: {
              theme: 'stripe',
              variables: { colorPrimary: '#a3e635' },
            },
          }}
        >
          <CheckoutForm onSuccess={onSuccess} onClose={onClose} />
        </Elements>
      </div>
    </div>
  )
}
