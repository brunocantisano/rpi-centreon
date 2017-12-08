our %centreontrapd_config = (
    # Temps en secondes avant d'arrêter brutalement les sous processus
    timeout_end => 30,
    spool_directory => "/var/spool/centreontrapd/",
    # Délai entre deux contrôles du répertoire de "spool" pour détecter de nouveaux fichiers à traiter
    sleep => 2,
    # 1 = utiliser la date et heure du traitement e l'évènement par centreontrapdforward
    use_trap_time => 1,
    net_snmp_perl_enable => 1,
    mibs_environment => '',
    remove_backslash_from_quotes => 1,
    dns_enable => 0,
    # Séparateur à appliquer lors de la substitution des arguments
    separator => ' ',
    strip_domain => 0,
    strip_domain_list => [],
    duplicate_trap_window => 1,
    date_format => "",
    time_format => "",
    date_time_format => "",
    # Utiliser le cache d'OID interne de la base de données
    cache_unknown_traps_enable => 1,
    # Temps en secondes avant de recharger le cache
    cache_unknown_traps_retention => 600,
    # 0 = central, 1 = poller
    mode => 1,
    cmd_timeout => 10,
    centreon_user => "centreon",
    # 0 => continuer en cas d'erreur MySQL | 1 => ne pas continuer le traitement (blocage) en cas d'erreur MySQL
    policy_trap => 1,
    # Enregistrement des journaux en base de données
    log_trap_db => 0,
    log_transaction_request_max => 500,
    log_transaction_timeout => 10,
    log_purge_time => 600
);

1;
