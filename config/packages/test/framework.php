<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function (ContainerConfigurator $container): void
{
	$container->extension('framework', [
		'test' => true,
		'session' => [
			'storage_factory_id' => 'session.storage.factory.mock_file',
		],
	]);
};
