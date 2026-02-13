<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function (ContainerConfigurator $container): void
{
	$container->extension('framework', [
		'router' => [
			'default_uri' => '%env(DEFAULT_URI)%',
		],
	]);
};
