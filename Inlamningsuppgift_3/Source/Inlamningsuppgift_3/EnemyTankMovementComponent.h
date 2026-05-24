#pragma once

#include "CoreMinimal.h"
#include "GameFramework/FloatingPawnMovement.h"
#include "EnemyTankMovementComponent.generated.h"

UCLASS()
class INLAMNINGSUPPGIFT_3_API UEnemyTankMovementComponent : public UFloatingPawnMovement
{
    GENERATED_BODY()

public:
    UEnemyTankMovementComponent();

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Tank")
    float TurnSpeed = 120.0f;

    virtual void RequestDirectMove(const FVector& MoveVelocity, bool bForceMaxSpeed) override;
};