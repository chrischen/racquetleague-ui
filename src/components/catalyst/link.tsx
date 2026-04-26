/**
 * TODO: Update this component to use your client-side framework's link
 * component. We've provided examples of how to do this for Next.js, Remix, and
 * Inertia.js in the Catalyst documentation:
 *
 * https://catalyst.tailwindui.com/docs#client-side-router-integration
 */

import * as Headless from '@headlessui/react'
import React, { forwardRef } from 'react'
import { NavLink } from 'react-router-dom'
import { Router_useLocalePath } from '../shared/LangProvider.gen'

export const Link = forwardRef(function Link(
  props: { href: string } & React.ComponentPropsWithoutRef<'a'>,
  ref: React.ForwardedRef<HTMLAnchorElement>
) {
  const localePath = Router_useLocalePath()
  const { href, ...rest } = props

  return (
    <Headless.DataInteractive>
      <NavLink to={localePath(href)} {...rest} ref={ref} />
    </Headless.DataInteractive>
  )
})
