<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function (ContainerConfigurator $container): void
{
	$container->extension('framework', [
		'mailer' => [
			'dsn' => '%env(MAILER_DSN)%',
		],
	]);
};
