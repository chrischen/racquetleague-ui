import React, {forwardRef} from 'react';
import { GripVertical } from 'lucide-react';

import {Action, ActionProps} from '../Action';

export const Handle = forwardRef<HTMLButtonElement, ActionProps>(
  (props, ref) => {
    return (
      <Action
        ref={ref}
        cursor="grab"
        data-cypress="draggable-handle"
        {...props}
      >
        <GripVertical className="w-5 h-5 text-slate-400" />
      </Action>
    );
  }
);
