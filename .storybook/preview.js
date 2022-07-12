import { Provider as ReduxProvider } from 'react-redux';
import { PersistGate } from 'redux-persist/integration/react';
import store, { persistor } from 'store';

import 'assets/globals.css';

import * as NextImage from 'next/image';

import { setupWorker, rest } from 'msw';

if (typeof global.process === 'undefined') {
  const worker = setupWorker(
    rest.get('http://localhost:3000/api/hello', (req, res, ctx) => {
      return res(ctx.json({ name: 'John Doh' }));
    })
  );
  worker.start();
}

const BREAKPOINTS_INT = {
  xs: 375,
  sm: 600,
  md: 900,
  lg: 1200,
  xl: 1536,
};

const customViewports = Object.fromEntries(
  Object.entries(BREAKPOINTS_INT).map(([key, val], idx) => {
    console.log(val);
    return [
      key,
      {
        name: key,
        styles: {
          width: `${val}px`,
          height: `${(idx + 5) * 10}vh`,
        },
      },
    ];
  })
);

const OriginalNextImage = NextImage.default;

Object.defineProperty(NextImage, 'default', {
  configurable: true,
  value: props => <OriginalNextImage {...props} unoptimized />,
});

export const decorators = [
  Story => (
    <ReduxProvider store={store}>
      {/*@ts-ignore TYPE NEEDS FIXING*/}
      <PersistGate persistor={persistor}>
        <Story />
      </PersistGate>
    </ReduxProvider>
  ),
];

export const parameters = {
  actions: { argTypesRegex: '^on[A-Z].*' },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
  viewport: { viewports: customViewports },
};
