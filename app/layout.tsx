import './globals.css';
import { ReactNode } from 'react';

export default function RootLayout({ children }: { children: ReactNode }) {
	return (
		<html lang='en'>
			<body className='min-h-screen bg-slate-600 text-neutral-100 antialiased'>
				<div className='mx-auto max-w-7xl p-6'>{children}</div>
			</body>
		</html>
	);
}
