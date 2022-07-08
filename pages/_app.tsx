import { useEffect, useState } from 'react';
import { Provider as ReduxProvider } from 'react-redux';
import { PersistGate } from 'redux-persist/integration/react';
import { DefaultSeo } from 'next-seo';
import { useRouter } from 'next/router';
import SEO from '../next-seo.config';
import { AppLayout } from '@components/layouts/AppLayout';
import store, { persistor } from 'store';

// Styles
import '../assets/sass/style.scss';
import '../assets/sass/tailwind.scss';

// @ts-ignore TYPE NEEDS FIXING
function MyApp({ Component, pageProps }) {
  const { events: routerEvents } = useRouter();
  const [pageLoading, setPageLoading] = useState<boolean>(false);

  useEffect(() => {
    const startLoader = () => {
      setPageLoading(true);
    };

    const stopLoader = () => {
      setPageLoading(false);
    };

    routerEvents.on('routeChangeStart', startLoader);
    routerEvents.on('routeChangeComplete', stopLoader);
    routerEvents.on('routeChangeError', stopLoader);
  }, [routerEvents]);

  return (
    <ReduxProvider store={store}>
      {/*@ts-ignore TYPE NEEDS FIXING*/}
      <PersistGate persistor={persistor}>
        <DefaultSeo
          {...SEO}
          additionalMetaTags={[
            {
              httpEquiv: 'content-type',
              content: 'text/html; charset=utf-8',
            },
            {
              name: 'viewport',
              content: 'width=device-width, initial-scale=1, shrink-to-fit=no',
            },
            {
              httpEquiv: 'x-ua-compatible',
              content: 'IE=edge; chrome=1',
            },
          ]}
        />
        {pageLoading ? <div className="loader"></div> : ''}
        <AppLayout>
          <Component {...pageProps} />
        </AppLayout>
      </PersistGate>
    </ReduxProvider>
  );
}

export default MyApp;
