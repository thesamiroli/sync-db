import * as Knex from 'knex';

import { dbLogger } from '../util/logger';
import MigrationCommandContext from '../domain/MigrationCommandContext';
import OperationResult from '../domain/operation/OperationResult';
import { executeOperation } from './execution';

/**
 * A map of Knex's migration API functions.
 */
export const migrationApiMap = {
  'migrate.latest': (trx: Knex | Knex.Transaction, config: Knex.MigratorConfig) => trx.migrate.latest(config),
  'migrate.rollback': (trx: Knex | Knex.Transaction, config: Knex.MigratorConfig) => trx.migrate.rollback(config),
  'migrate.list': (trx: Knex | Knex.Transaction, config: Knex.MigratorConfig) => trx.migrate.list(config)
};

/**
 * Invoke Knex's migration API for given function.
 *
 * @param {Knex.Transaction} trx
 * @param {MigrationCommandContext} context
 * @param {((trx: Knex | Knex.Transaction, config: Knex.MigratorConfig) => Promise<any>)} func
 * @returns {Promise<OperationResult>}
 */
export async function invokeMigrationApi(
  trx: Knex.Transaction,
  context: MigrationCommandContext,
  func: (trx: Knex | Knex.Transaction, config: Knex.MigratorConfig) => Promise<any>
): Promise<OperationResult> {
  return executeOperation(context, async () => {
    const { knexMigrationConfig } = context;
    const funcName = func.name || 'func';

    const dbLog = dbLogger(context.connectionId);
    dbLog(`BEGIN: ${funcName}`);
    const data = await func(trx, knexMigrationConfig);

    dbLog(`END: ${funcName}`);
    dbLog('Result:\n%O', data);

    return data;
  });
}
