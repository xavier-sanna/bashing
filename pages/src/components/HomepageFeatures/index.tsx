import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Bootstrap Scripts Fast',
    description: (
      <>
        Source <code>bootstrap.sh</code> or <code>load.sh</code> to resolve
        task paths and make the library available with minimal setup.
      </>
    ),
  },
  {
    title: 'Reuse Common Helpers',
    description: (
      <>
        Logging, dotenv parsing, Docker Compose detection, and optional
        privilege helpers are split into focused modules.
      </>
    ),
  },
  {
    title: 'Keep Output Readable',
    description: (
      <>
        UI helpers provide titles, tables, spinners, and status wrappers for
        terminal output that is easier to scan.
      </>
    ),
  },
];

function Feature({title, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
