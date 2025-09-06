// @ts-nocheck
"use client"

import { useCallback } from 'react';

export default function SideControl({ setter }: {
  setter: (update: string) => void
}) {
  const checked = false;
  const onChange = useCallback(() => setter(section), [section, setter]);

  return (
    <div className='p-2 sm:pb-2 divide-y-4 scrollbar-thin' data-nosnippet>
      <label className="inline-flex items-center">
        <input type='checkbox' className='sr-only peer' checked={checked} onChange={onChange} />
      </label>
    </div>
  );
}
