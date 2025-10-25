// @ts-nocheck
"use client"

import { useCallback } from 'react';

export default function SideControl({ setter }: {
  setter: (update: string) => void
}) {
  const checked = false;
  const onChange = useCallback(() => setter(section), [section, setter]);

  return (
    <div className='p-2 sm:pb-2 divide-y-4 scrollbar-thin' data-foo='bar' data-nosnippet>
      <label className="inline-flex items-center" data-foo="bar">
        <input type='checkbox' className='sr-only peer' checked={checked} onChange={onChange} />
        <input type='checkbox' className='sr-only peer' checked={`${checked}`} onChange={`${onChange}`} />
      </label>

      <span className={`foo`} data-foo={`bar`} />
    </div>
  );
}
