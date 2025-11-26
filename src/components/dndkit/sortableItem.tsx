import React from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';

export function SortableItem(props: { 
  id: string | number, 
  children: React.ReactNode,
  handle?: boolean 
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    setActivatorNodeRef,
  } = useSortable({ id: props.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  // Clone children and inject handle props if using handle pattern
  const children = props.handle && React.isValidElement(props.children)
    ? React.cloneElement(props.children as React.ReactElement, {
        // @ts-ignore - inject drag handle props
        dragHandleProps: { ref: setActivatorNodeRef, ...listeners },
      })
    : props.children;

  return (
    <div 
      ref={setNodeRef} 
      style={style} 
      {...attributes} 
      {...(!props.handle && listeners)}
    >
      {children}
    </div>
  );
}
